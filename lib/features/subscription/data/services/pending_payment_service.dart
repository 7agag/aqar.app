import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PendingInvoicePayment {
  final String invoiceId;
  final DateTime createdAt;

  const PendingInvoicePayment({
    required this.invoiceId,
    required this.createdAt,
  });

  factory PendingInvoicePayment.fromJson(Map<String, dynamic> json) {
    return PendingInvoicePayment(
      invoiceId: json['invoiceId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num).toInt()),
    );
  }

  Map<String, dynamic> toJson() => {
        'invoiceId': invoiceId,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}

class PendingSubscriptionPayment {
  final int propertyId;
  final String subscriptionId;
  final DateTime createdAt;

  const PendingSubscriptionPayment({
    required this.propertyId,
    required this.subscriptionId,
    required this.createdAt,
  });

  factory PendingSubscriptionPayment.fromJson(Map<String, dynamic> json) {
    return PendingSubscriptionPayment(
      propertyId: (json['propertyId'] as num).toInt(),
      subscriptionId: json['subscriptionId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num).toInt()),
    );
  }

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'subscriptionId': subscriptionId,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}

class PendingSponsorshipPayment {
  final int propertyId;
  final DateTime createdAt;

  const PendingSponsorshipPayment({
    required this.propertyId,
    required this.createdAt,
  });

  factory PendingSponsorshipPayment.fromJson(Map<String, dynamic> json) {
    return PendingSponsorshipPayment(
      propertyId: (json['propertyId'] as num).toInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num).toInt()),
    );
  }

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}

class PendingPaymentService {
  static const _subKey = 'pending_subscription_payment';
  static const _sponsorKey = 'pending_sponsorship_payment';
  static const _invoiceKey = 'pending_invoice_payment';

  Future<void> savePendingInvoicePayment(String invoiceId) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = PendingInvoicePayment(
      invoiceId: invoiceId,
      createdAt: DateTime.now(),
    );
    await prefs.setString(_invoiceKey, json.encode(payload.toJson()));
  }

  Future<PendingInvoicePayment?> loadPendingInvoicePayment() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_invoiceKey);
    if (raw == null) return null;
    try {
      return PendingInvoicePayment.fromJson(
          Map<String, dynamic>.from(json.decode(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingInvoicePayment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_invoiceKey);
  }

  Future<void> savePendingSubscriptionPayment(
    int propertyId,
    String subscriptionId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = PendingSubscriptionPayment(
      propertyId: propertyId,
      subscriptionId: subscriptionId,
      createdAt: DateTime.now(),
    );
    await prefs.setString(_subKey, json.encode(payload.toJson()));
  }

  Future<PendingSubscriptionPayment?> loadPendingSubscriptionPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_subKey);
    if (raw == null) return null;
    try {
      return PendingSubscriptionPayment.fromJson(
          Map<String, dynamic>.from(json.decode(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingSubscriptionPayment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subKey);
  }

  Future<void> savePendingSponsorshipPayment(int propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = PendingSponsorshipPayment(
      propertyId: propertyId,
      createdAt: DateTime.now(),
    );
    await prefs.setString(_sponsorKey, json.encode(payload.toJson()));
  }

  Future<PendingSponsorshipPayment?> loadPendingSponsorshipPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sponsorKey);
    if (raw == null) return null;
    try {
      return PendingSponsorshipPayment.fromJson(
          Map<String, dynamic>.from(json.decode(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingSponsorshipPayment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sponsorKey);
  }
}
