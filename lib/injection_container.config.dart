// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:aqar/core/di/injection_module.dart' as _i193;
import 'package:aqar/core/network/api_client.dart' as _i164;
import 'package:aqar/core/network/network_info.dart' as _i763;
import 'package:aqar/features/auth/data/datasources/auth_remote_datasource.dart'
    as _i898;
import 'package:aqar/features/auth/data/repositories/auth_repository_impl.dart'
    as _i1061;
import 'package:aqar/features/auth/domain/repositories/auth_repository.dart'
    as _i144;
import 'package:aqar/features/auth/domain/usecases/forgot_password_usecase.dart'
    as _i394;
import 'package:aqar/features/auth/domain/usecases/get_profile_usecase.dart'
    as _i925;
import 'package:aqar/features/auth/domain/usecases/login_usecase.dart' as _i376;
import 'package:aqar/features/auth/domain/usecases/logout_usecase.dart'
    as _i950;
import 'package:aqar/features/auth/domain/usecases/register_usecase.dart'
    as _i669;
import 'package:aqar/features/auth/domain/usecases/request_otp_usecase.dart'
    as _i352;
import 'package:aqar/features/auth/domain/usecases/reset_password_usecase.dart'
    as _i597;
import 'package:aqar/features/auth/domain/usecases/verify_otp_usecase.dart'
    as _i806;
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart' as _i749;
import 'package:aqar/features/favorite/data/datasources/favorite_remote_data_source.dart'
    as _i352;
import 'package:aqar/features/favorite/data/repositories/favorite_repository_impl.dart'
    as _i913;
import 'package:aqar/features/favorite/domain/repositories/favorite_repository.dart'
    as _i419;
import 'package:aqar/features/favorite/domain/usecases/add_to_favorite_usecase.dart'
    as _i617;
import 'package:aqar/features/favorite/domain/usecases/get_favorites_usecase.dart'
    as _i524;
import 'package:aqar/features/favorite/domain/usecases/remove_from_favorite_usecase.dart'
    as _i963;
import 'package:aqar/features/favorite/presentation/bloc/favorite_bloc.dart'
    as _i717;
import 'package:aqar/features/property/data/datasources/property_remote_datasource.dart'
    as _i359;
import 'package:aqar/features/property/data/repositories/property_repository_impl.dart'
    as _i985;
import 'package:aqar/features/property/domain/repositories/property_repository.dart'
    as _i268;
import 'package:aqar/features/property/domain/usecases/get_my_properties_usecase.dart'
    as _i29;
import 'package:aqar/features/property/domain/usecases/get_properties_usecase.dart'
    as _i247;
import 'package:aqar/features/property/domain/usecases/get_property_by_id_usecase.dart'
    as _i240;
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart'
    as _i411;
import 'package:aqar/features/rent_request/data/datasources/rent_request_remote_datasource.dart'
    as _i866;
import 'package:aqar/features/rent_request/data/repositories/rent_request_repository_impl.dart'
    as _i964;
import 'package:aqar/features/rent_request/domain/repositories/rent_request_repository.dart'
    as _i719;
import 'package:aqar/features/rent_request/domain/usecases/accept_rent_request_usecase.dart'
    as _i721;
import 'package:aqar/features/rent_request/domain/usecases/cancel_rent_request_usecase.dart'
    as _i363;
import 'package:aqar/features/rent_request/domain/usecases/create_rent_request_usecase.dart'
    as _i1058;
import 'package:aqar/features/rent_request/domain/usecases/get_received_requests_usecase.dart'
    as _i47;
import 'package:aqar/features/rent_request/domain/usecases/get_sent_requests_usecase.dart'
    as _i994;
import 'package:aqar/features/rent_request/domain/usecases/reject_rent_request_usecase.dart'
    as _i1015;
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart'
    as _i615;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:internet_connection_checker/internet_connection_checker.dart'
    as _i973;

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
    gh.singleton<_i164.ApiClient>(
        () => _i164.ApiClient(gh<_i558.FlutterSecureStorage>()));
    gh.factory<_i898.AuthRemoteDataSource>(
        () => _i898.AuthRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i763.NetworkInfo>(
        () => _i763.NetworkInfoImpl(gh<_i973.InternetConnectionChecker>()));
    gh.factory<_i359.PropertyRemoteDataSource>(
        () => _i359.PropertyRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i352.FavoriteRemoteDataSource>(
        () => _i352.FavoriteRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i144.AuthRepository>(() => _i1061.AuthRepositoryImpl(
          gh<_i898.AuthRemoteDataSource>(),
          gh<_i558.FlutterSecureStorage>(),
        ));
    gh.factory<_i866.RentRequestRemoteDataSource>(
        () => _i866.RentRequestRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i268.PropertyRepository>(() =>
        _i985.PropertyRepositoryImpl(gh<_i359.PropertyRemoteDataSource>()));
    gh.factory<_i394.ForgotPasswordUseCase>(
        () => _i394.ForgotPasswordUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i925.GetProfileUseCase>(
        () => _i925.GetProfileUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i376.LoginUseCase>(
        () => _i376.LoginUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i950.LogoutUseCase>(
        () => _i950.LogoutUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i669.RegisterUseCase>(
        () => _i669.RegisterUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i352.RequestOtpUseCase>(
        () => _i352.RequestOtpUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i597.ResetPasswordUseCase>(
        () => _i597.ResetPasswordUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i806.VerifyOtpUseCase>(
        () => _i806.VerifyOtpUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i749.AuthBloc>(() => _i749.AuthBloc(
          loginUseCase: gh<_i376.LoginUseCase>(),
          registerUseCase: gh<_i669.RegisterUseCase>(),
          logoutUseCase: gh<_i950.LogoutUseCase>(),
          forgotPasswordUseCase: gh<_i394.ForgotPasswordUseCase>(),
          resetPasswordUseCase: gh<_i597.ResetPasswordUseCase>(),
          verifyOtpUseCase: gh<_i806.VerifyOtpUseCase>(),
          requestOtpUseCase: gh<_i352.RequestOtpUseCase>(),
          getProfileUseCase: gh<_i925.GetProfileUseCase>(),
          secureStorage: gh<_i558.FlutterSecureStorage>(),
        ));
    gh.factory<_i29.GetMyPropertiesUseCase>(
        () => _i29.GetMyPropertiesUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i247.GetPropertiesUseCase>(
        () => _i247.GetPropertiesUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i240.GetPropertyByIdUseCase>(
        () => _i240.GetPropertyByIdUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i411.PropertyBloc>(() => _i411.PropertyBloc(
          gh<_i247.GetPropertiesUseCase>(),
          gh<_i240.GetPropertyByIdUseCase>(),
          gh<_i29.GetMyPropertiesUseCase>(),
        ));
    gh.factory<_i719.RentRequestRepository>(() =>
        _i964.RentRequestRepositoryImpl(
            gh<_i866.RentRequestRemoteDataSource>()));
    gh.factory<_i419.FavoriteRepository>(() =>
        _i913.FavoriteRepositoryImpl(gh<_i352.FavoriteRemoteDataSource>()));
    gh.factory<_i721.AcceptRentRequestUseCase>(() =>
        _i721.AcceptRentRequestUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i363.CancelRentRequestUseCase>(() =>
        _i363.CancelRentRequestUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i1058.CreateRentRequestUseCase>(() =>
        _i1058.CreateRentRequestUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i47.GetReceivedRequestsUseCase>(() =>
        _i47.GetReceivedRequestsUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i994.GetSentRequestsUseCase>(
        () => _i994.GetSentRequestsUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i1015.RejectRentRequestUseCase>(() =>
        _i1015.RejectRentRequestUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i615.RentRequestBloc>(() => _i615.RentRequestBloc(
          getSentRequests: gh<_i994.GetSentRequestsUseCase>(),
          getReceivedRequests: gh<_i47.GetReceivedRequestsUseCase>(),
          createRequest: gh<_i1058.CreateRentRequestUseCase>(),
          acceptRequest: gh<_i721.AcceptRentRequestUseCase>(),
          rejectRequest: gh<_i1015.RejectRentRequestUseCase>(),
          cancelRequest: gh<_i363.CancelRentRequestUseCase>(),
        ));
    gh.factory<_i617.AddToFavoriteUseCase>(
        () => _i617.AddToFavoriteUseCase(gh<_i419.FavoriteRepository>()));
    gh.factory<_i524.GetFavoritesUseCase>(
        () => _i524.GetFavoritesUseCase(gh<_i419.FavoriteRepository>()));
    gh.factory<_i963.RemoveFromFavoriteUseCase>(
        () => _i963.RemoveFromFavoriteUseCase(gh<_i419.FavoriteRepository>()));
    gh.factory<_i717.FavoriteBloc>(() => _i717.FavoriteBloc(
          addToFavorite: gh<_i617.AddToFavoriteUseCase>(),
          removeFromFavorite: gh<_i963.RemoveFromFavoriteUseCase>(),
          getFavorites: gh<_i524.GetFavoritesUseCase>(),
        ));
    return this;
  }
}

class _$InjectionModule extends _i193.InjectionModule {}
