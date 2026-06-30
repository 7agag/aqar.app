import 'package:equatable/equatable.dart';
import 'package:aqar/core/utils/parse_utils.dart';

class InvoiceEntity extends Equatable {
  final String invoiceId;
  final String leaseId;
  final String renterId;
  final String ownerId;
  final double amount;
  final DateTime dueDate;
  final String status;
  final String? kashierOrderId;
  final DateTime? paidAt;
  final DateTime createdAt;
  final int? propertyId;
  final String? propertyName;
  final String? location;

  const InvoiceEntity({
    required this.invoiceId,
    required this.leaseId,
    required this.renterId,
    required this.ownerId,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.kashierOrderId,
    this.paidAt,
    required this.createdAt,
    this.propertyId,
    this.propertyName,
    this.location,
  });

  factory InvoiceEntity.fromJson(Map<String, dynamic> json) {
    return InvoiceEntity(
      invoiceId: json['invoice_id'] as String? ?? '',
      leaseId: json['lease_id'] as String? ?? '',
      renterId: json['renter_id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      amount: parseDouble(json['amount']),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'UNPAID',
      kashierOrderId: json['kashier_order_id'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      propertyId: json['property_id'] as int?,
      propertyName: json['property_name'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'invoice_id': invoiceId,
    'lease_id': leaseId,
    'renter_id': renterId,
    'owner_id': ownerId,
    'amount': amount,
    'due_date': dueDate.toIso8601String().split('T')[0],
    'status': status,
    'kashier_order_id': kashierOrderId,
    'paid_at': paidAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'property_id': propertyId,
    'property_name': propertyName,
    'location': location,
  };

  bool get isPaid => status == 'PAID';
  bool get isOverdue => status == 'OVERDUE';
  bool get isUnpaid => status == 'UNPAID';

  @override
  List<Object?> get props => [
    invoiceId, leaseId, renterId, ownerId, amount, dueDate, status,
    kashierOrderId, paidAt, createdAt, propertyId, propertyName, location,
  ];
}

class InvoiceStatsEntity extends Equatable {
  final RenterStats asRenter;
  final OwnerStats asOwner;

  const InvoiceStatsEntity({
    required this.asRenter,
    required this.asOwner,
  });

  factory InvoiceStatsEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final renter = (data['asRenter'] as Map<String, dynamic>?) ?? {};
    final owner = (data['asOwner'] as Map<String, dynamic>?) ?? {};
    return InvoiceStatsEntity(
      asRenter: RenterStats.fromJson(renter),
      asOwner: OwnerStats.fromJson(owner),
    );
  }

  @override
  List<Object?> get props => [asRenter, asOwner];
}

class RenterStats extends Equatable {
  final int totalInvoices;
  final int unpaidCount;
  final int overdueCount;
  final int paidCount;
  final double totalDue;
  final DateTime? nextDueDate;

  const RenterStats({
    this.totalInvoices = 0,
    this.unpaidCount = 0,
    this.overdueCount = 0,
    this.paidCount = 0,
    this.totalDue = 0.0,
    this.nextDueDate,
  });

  factory RenterStats.fromJson(Map<String, dynamic> json) {
    return RenterStats(
      totalInvoices: (json['total_invoices'] as int?) ?? 0,
      unpaidCount: (json['unpaid_count'] as int?) ?? 0,
      overdueCount: (json['overdue_count'] as int?) ?? 0,
      paidCount: (json['paid_count'] as int?) ?? 0,
      totalDue: parseDouble(json['total_due']),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.tryParse(json['next_due_date'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [totalInvoices, unpaidCount, overdueCount, paidCount, totalDue, nextDueDate];
}

class OwnerStats extends Equatable {
  final int totalInvoices;
  final int pendingCount;
  final int paidCount;
  final double expectedIncome;
  final int delinquentTenants;

  const OwnerStats({
    this.totalInvoices = 0,
    this.pendingCount = 0,
    this.paidCount = 0,
    this.expectedIncome = 0.0,
    this.delinquentTenants = 0,
  });

  factory OwnerStats.fromJson(Map<String, dynamic> json) {
    return OwnerStats(
      totalInvoices: (json['total_invoices'] as int?) ?? 0,
      pendingCount: (json['pending_count'] as int?) ?? 0,
      paidCount: (json['paid_count'] as int?) ?? 0,
      expectedIncome: parseDouble(json['expected_income']),
      delinquentTenants: (json['delinquent_tenants'] as int?) ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [totalInvoices, pendingCount, paidCount, expectedIncome, delinquentTenants];
}
