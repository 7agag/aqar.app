import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

@injectable
class GetInvoiceStatsUseCase
    extends UseCase<InvoiceStatsEntity, NoParams> {
  final InvoiceRepository repository;
  GetInvoiceStatsUseCase(this.repository);

  @override
  Future<Either<Failure, InvoiceStatsEntity>> call(NoParams params) {
    return repository.getInvoiceStats();
  }
}
