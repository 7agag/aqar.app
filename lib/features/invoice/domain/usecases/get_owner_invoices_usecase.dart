import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

@injectable
class GetOwnerInvoicesUseCase
    extends UseCase<List<InvoiceEntity>, NoParams> {
  final InvoiceRepository repository;
  GetOwnerInvoicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<InvoiceEntity>>> call(NoParams params) {
    return repository.getOwnerInvoices();
  }
}
