import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_datasource.dart';

@Injectable(as: InvoiceRepository)
class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;
  InvoiceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getRenterInvoices() async {
    try {
      final result = await remoteDataSource.getRenterInvoices();
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getOwnerInvoices() async {
    try {
      final result = await remoteDataSource.getOwnerInvoices();
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, InvoiceStatsEntity>> getInvoiceStats() async {
    try {
      final result = await remoteDataSource.getInvoiceStats();
      return Right(result);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
