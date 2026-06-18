enum RentRequestState {
  pending,
  accepted,
  rejected,
  cancelled,
  paymentPending,
  paid;

  String get label {
    switch (this) {
      case RentRequestState.pending:
        return 'Pending';
      case RentRequestState.accepted:
        return 'Accepted';
      case RentRequestState.rejected:
        return 'Rejected';
      case RentRequestState.cancelled:
        return 'Cancelled';
      case RentRequestState.paymentPending:
        return 'Payment Pending';
      case RentRequestState.paid:
        return 'Paid';
    }
  }

  static RentRequestState fromValue(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return RentRequestState.pending;
      case 'ACCEPTED':
        return RentRequestState.accepted;
      case 'REJECTED':
        return RentRequestState.rejected;
      case 'CANCELLED':
        return RentRequestState.cancelled;
      case 'PAYMENT_PENDING':
        return RentRequestState.paymentPending;
      case 'PAID':
        return RentRequestState.paid;
      default:
        return RentRequestState.pending;
    }
  }
}

enum RentingType {
  day,
  month;

  String get value {
    switch (this) {
      case RentingType.day:
        return 'DAY';
      case RentingType.month:
        return 'MONTH';
    }
  }

  String get label {
    switch (this) {
      case RentingType.day:
        return 'Daily';
      case RentingType.month:
        return 'Monthly';
    }
  }

  static RentingType fromValue(String value) {
    switch (value.toUpperCase()) {
      case 'DAY':
        return RentingType.day;
      case 'MONTH':
        return RentingType.month;
      default:
        return RentingType.day;
    }
  }
}
