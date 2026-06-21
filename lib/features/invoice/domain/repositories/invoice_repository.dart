import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/invoice_entity.dart';

abstract class InvoiceRepository {
  Future<Either<Failure, List<InvoiceEntity>>> getRenterInvoices();
  Future<Either<Failure, List<InvoiceEntity>>> getOwnerInvoices();
  Future<Either<Failure, InvoiceStatsEntity>> getInvoiceStats();
}
