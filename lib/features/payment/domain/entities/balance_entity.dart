import 'package:equatable/equatable.dart';

class BalanceEntity extends Equatable {
  final double balance;
  final double lockedFunds;
  final double availableBalance;
  final String currency;

  const BalanceEntity({
    this.balance = 0.0,
    this.lockedFunds = 0.0,
    this.availableBalance = 0.0,
    this.currency = 'EGP',
  });

  factory BalanceEntity.fromJson(Map<String, dynamic> json) {
    return BalanceEntity(
      balance: double.tryParse(json['balance']?.toString() ?? '') ?? 0.0,
      lockedFunds: double.tryParse(json['lockedFunds']?.toString() ?? '') ?? 0.0,
      availableBalance:
          double.tryParse(json['availableBalance']?.toString() ?? '') ?? 0.0,
      currency: json['currency'] as String? ?? 'EGP',
    );
  }

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'lockedFunds': lockedFunds,
    'availableBalance': availableBalance,
    'currency': currency,
  };

  @override
  List<Object?> get props =>
      [balance, lockedFunds, availableBalance, currency];
}
