import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

@injectable
class GetTransactionsUseCase
    extends UseCase<List<TransactionEntity>, NoParams> {
  final PaymentRepository repository;
  GetTransactionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(NoParams params) {
    return repository.getTransactions();
  }
}
