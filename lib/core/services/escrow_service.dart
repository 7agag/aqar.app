import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

enum LeaseStatus {
  awaitingPayment,
  escrowActive,
  tenantConfirmed,
  completed,
  cancelled,
}

class LocalLease {
  final String requestId;
  final int propertyId;
  final String renterId;
  final String ownerId;
  final String? chatId;
  final DateTime paidAt;
  final DateTime deadline;
  final bool renterConfirmed;
  final bool moneySent;
  final LeaseStatus status;

  const LocalLease({
    required this.requestId,
    required this.propertyId,
    required this.renterId,
    required this.ownerId,
    this.chatId,
    required this.paidAt,
    required this.deadline,
    this.renterConfirmed = false,
    this.moneySent = false,
    this.status = LeaseStatus.escrowActive,
  });

  Duration get remaining => deadline.difference(DateTime.now());
  bool get isExpired => remaining.isNegative;

  LocalLease copyWith({
    String? chatId,
    bool? renterConfirmed,
    bool? moneySent,
    LeaseStatus? status,
  }) {
    return LocalLease(
      requestId: requestId,
      propertyId: propertyId,
      renterId: renterId,
      ownerId: ownerId,
      chatId: chatId ?? this.chatId,
      paidAt: paidAt,
      deadline: deadline,
      renterConfirmed: renterConfirmed ?? this.renterConfirmed,
      moneySent: moneySent ?? this.moneySent,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'propertyId': propertyId,
        'renterId': renterId,
        'ownerId': ownerId,
        'chatId': chatId,
        'paidAt': paidAt.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'renterConfirmed': renterConfirmed,
        'moneySent': moneySent,
        'status': status.name,
      };

  factory LocalLease.fromJson(Map<String, dynamic> json) {
    return LocalLease(
      requestId: json['requestId'] as String,
      propertyId: json['propertyId'] as int,
      renterId: json['renterId'] as String,
      ownerId: json['ownerId'] as String,
      chatId: json['chatId'] as String?,
      paidAt: DateTime.parse(json['paidAt'] as String),
      deadline: DateTime.parse(json['deadline'] as String),
      renterConfirmed: json['renterConfirmed'] as bool? ?? false,
      moneySent: json['moneySent'] as bool? ?? false,
      status: LeaseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeaseStatus.escrowActive,
      ),
    );
  }
}

class EscrowService extends ChangeNotifier {
  Map<String, LocalLease> _leases = {};
  Timer? _countdownTimer;
  final _controller = StreamController<Map<String, LocalLease>>.broadcast();

  Stream<Map<String, LocalLease>> get stream => _controller.stream;

  LocalLease? getLease(String requestId) => _leases[requestId];

  LocalLease? getLeaseByProperty(int propertyId) {
    for (final lease in _leases.values) {
      if (lease.propertyId == propertyId) return lease;
    }
    return null;
  }

  List<LocalLease> getActiveLeases() =>
      _leases.values.where((l) => l.status == LeaseStatus.escrowActive).toList();

  Future<void> init() async {
    await _loadFromPrefs();
    await _cleanupStale();
    await checkPending();
    _startCountdown();
  }

  Future<void> createLease({
    required String requestId,
    required int propertyId,
    required String renterId,
    required String ownerId,
    String? chatId,
  }) async {
    final now = DateTime.now();
    final lease = LocalLease(
      requestId: requestId,
      propertyId: propertyId,
      renterId: renterId,
      ownerId: ownerId,
      chatId: chatId,
      paidAt: now,
      deadline: now.add(const Duration(days: 3)),
    );
    _leases[requestId] = lease;
    await _saveToPrefs();
    _notify();
    try {
      final notificationService = GetIt.instance<NotificationService>();
      await notificationService.scheduleLeaseReminder(
        requestId: requestId,
        deadlineMillis: lease.deadline.millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<void> confirmReceipt(String requestId) async {
    final lease = _leases[requestId];
    if (lease == null || lease.status != LeaseStatus.escrowActive) return;
    _leases[requestId] = lease.copyWith(
      renterConfirmed: true,
      moneySent: true,
      status: LeaseStatus.completed,
    );
    await _saveToPrefs();
    _notify();
  }

  Future<void> cancelLease(String requestId) async {
    final lease = _leases[requestId];
    if (lease == null) return;
    _leases[requestId] = lease.copyWith(status: LeaseStatus.cancelled);
    await _saveToPrefs();
    _notify();
  }

  Future<void> checkPending() async {
    bool changed = false;
    for (final entry in _leases.entries.toList()) {
      final lease = entry.value;
      if (lease.status == LeaseStatus.escrowActive && lease.isExpired && !lease.moneySent) {
        _leases[entry.key] = lease.copyWith(
          moneySent: true,
          status: LeaseStatus.completed,
        );
        changed = true;
      }
    }
    if (changed) {
      await _saveToPrefs();
      _notify();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.close();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await checkPending();
      _notify();
    });
  }

  Future<void> _cleanupStale() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    bool changed = false;
    _leases.removeWhere((key, lease) {
      if (lease.status == LeaseStatus.completed || lease.status == LeaseStatus.cancelled) {
        if (lease.paidAt.isBefore(cutoff)) {
          changed = true;
          return true;
        }
      }
      return false;
    });
    if (changed) await _saveToPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('escrow_leases');
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _leases = decoded.map((k, v) => MapEntry(k, LocalLease.fromJson(v as Map<String, dynamic>)));
    } catch (e) {
      dev.log('Failed to load escrow leases: $e', name: 'EscrowService');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_leases.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString('escrow_leases', raw);
    } catch (e) {
      dev.log('Failed to save escrow leases: $e', name: 'EscrowService');
    }
  }

  void _notify() {
    notifyListeners();
    _controller.add(Map.from(_leases));
  }
}
