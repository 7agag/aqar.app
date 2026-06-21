import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

@injectable
class GetRenterInvoicesUseCase
    extends UseCase<List<InvoiceEntity>, NoParams> {
  final InvoiceRepository repository;
  GetRenterInvoicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<InvoiceEntity>>> call(NoParams params) {
    return repository.getRenterInvoices();
  }
}
