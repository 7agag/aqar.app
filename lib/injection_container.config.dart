// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:aqar/features/auth/domain/usecases/verify_otp_usecase.dart'
    as _i8;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:internet_connection_checker/internet_connection_checker.dart'
    as _i973;

import 'core/di/injection_module.dart' as _i571;
import 'core/network/api_client.dart' as _i871;
import 'core/network/network_info.dart' as _i75;
import 'features/auth/data/datasources/auth_remote_datasource.dart' as _i588;
import 'features/auth/data/repositories/auth_repository_impl.dart' as _i111;
import 'features/auth/domain/repositories/auth_repository.dart' as _i1015;
import 'features/auth/domain/usecases/forgot_password_usecase.dart' as _i633;
import 'features/auth/domain/usecases/login_usecase.dart' as _i206;
import 'features/auth/domain/usecases/logout_usecase.dart' as _i824;
import 'features/auth/domain/usecases/register_usecase.dart' as _i693;
import 'features/auth/domain/usecases/request_otp_usecase.dart' as _i324;
import 'features/auth/domain/usecases/reset_password_usecase.dart' as _i742;
import 'features/auth/presentation/bloc/auth_bloc.dart' as _i363;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final injectionModule = _$InjectionModule();
    gh.singleton<_i558.FlutterSecureStorage>(
        () => injectionModule.secureStorage);
    gh.singleton<_i973.InternetConnectionChecker>(
        () => injectionModule.connectionChecker);
    gh.singleton<_i871.ApiClient>(
        () => _i871.ApiClient(gh<_i558.FlutterSecureStorage>()));
    gh.factory<_i588.AuthRemoteDataSource>(
        () => _i588.AuthRemoteDataSourceImpl(gh<_i871.ApiClient>()));
    gh.factory<_i75.NetworkInfo>(
        () => _i75.NetworkInfoImpl(gh<_i973.InternetConnectionChecker>()));
    gh.factory<_i1015.AuthRepository>(() => _i111.AuthRepositoryImpl(
          gh<_i588.AuthRemoteDataSource>(),
          gh<_i558.FlutterSecureStorage>(),
        ));
    gh.factory<_i206.LoginUseCase>(
        () => _i206.LoginUseCase(gh<_i1015.AuthRepository>()));
    gh.factory<_i633.ForgotPasswordUseCase>(
        () => _i633.ForgotPasswordUseCase(gh<_i1015.AuthRepository>()));
    gh.factory<_i742.ResetPasswordUseCase>(
        () => _i742.ResetPasswordUseCase(gh<_i1015.AuthRepository>()));
    gh.factory<_i824.LogoutUseCase>(
        () => _i824.LogoutUseCase(gh<_i1015.AuthRepository>()));
    gh.factory<_i693.RegisterUseCase>(
        () => _i693.RegisterUseCase(gh<_i1015.AuthRepository>()));
    gh.factory<_i8.VerifyOtpUseCase>(
        () => _i8.VerifyOtpUseCase(gh<_i1015.AuthRepository>()));
    gh.factory<_i324.RequestOtpUseCase>(
        () => _i324.RequestOtpUseCase(gh<_i1015.AuthRepository>()));
    gh.factory<_i363.AuthBloc>(() => _i363.AuthBloc(
          loginUseCase: gh<_i206.LoginUseCase>(),
          registerUseCase: gh<_i693.RegisterUseCase>(),
          logoutUseCase: gh<_i824.LogoutUseCase>(),
          verifyOtpUseCase: gh<_i8.VerifyOtpUseCase>(),
          requestOtpUseCase: gh<_i324.RequestOtpUseCase>(),
          forgotPasswordUseCase: gh<_i633.ForgotPasswordUseCase>(),
          resetPasswordUseCase: gh<_i742.ResetPasswordUseCase>(),
        ));
    return this;
  }
}

class _$InjectionModule extends _i571.InjectionModule {}
