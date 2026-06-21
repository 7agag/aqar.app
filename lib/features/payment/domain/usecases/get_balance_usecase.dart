import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/balance_entity.dart';
import '../repositories/payment_repository.dart';

@injectable
class GetBalanceUseCase extends UseCase<BalanceEntity, NoParams> {
  final PaymentRepository repository;
  GetBalanceUseCase(this.repository);

  @override
  Future<Either<Failure, BalanceEntity>> call(NoParams params) {
    return repository.getBalance();
  }
}
