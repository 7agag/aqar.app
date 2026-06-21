import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';
import '../../domain/entities/balance_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/get_balance_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/request_withdrawal_usecase.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';

@injectable
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetBalanceUseCase getBalance;
  final GetTransactionsUseCase getTransactions;
  final RequestWithdrawalUseCase requestWithdrawal;

  WalletBloc({
    required this.getBalance,
    required this.getTransactions,
    required this.requestWithdrawal,
  }) : super(WalletInitial()) {

    on<GetWalletDataRequested>((event, emit) async {
      emit(WalletLoading());
      final results = await Future.wait([
        getBalance(NoParams()),
        getTransactions(NoParams()),
      ]);
      final balanceResult =
          results[0] as Either<Failure, BalanceEntity>;
      final txResult =
          results[1] as Either<Failure, List<TransactionEntity>>;

      balanceResult.fold(
        (failure) => emit(WalletError(failure.message)),
        (balance) {
          txResult.fold(
            (failure) => emit(WalletError(failure.message)),
            (transactions) =>
                emit(WalletLoaded(balance: balance, transactions: transactions)),
          );
        },
      );
    });

    on<RequestWithdrawalTriggered>((event, emit) async {
      final current = state;
      if (current is WalletLoading) return;
      emit(WalletLoading());
      final result = await requestWithdrawal(RequestWithdrawalParams(
        amount: event.amount,
        method: event.method,
        receiverData: event.receiverData,
      ));
      result.fold(
        (failure) => emit(WalletError(failure.message)),
        (_) {
          add(const GetWalletDataRequested());
        },
      );
    });
  }
}
