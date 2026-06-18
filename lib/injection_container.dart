// lib/injection_container.dart

import 'package:aqar/core/network/network_info.dart';
import 'package:aqar/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:aqar/features/property/data/datasources/property_remote_datasource.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:aqar/features/auth/domain/repositories/auth_repository.dart';
import 'package:aqar/features/auth/domain/usecases/login_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/register_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/logout_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/request_otp_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:aqar/features/property/data/repositories/property_repository_impl.dart';
import 'package:aqar/features/property/domain/repositories/property_repository.dart';
import 'package:aqar/features/property/domain/usecases/get_properties_usecase.dart';
import 'package:aqar/features/property/domain/usecases/get_property_by_id_usecase.dart';
import 'package:aqar/features/property/domain/usecases/get_my_properties_usecase.dart';
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart';

// ========== FAVORITE IMPORTS ==========
import 'package:aqar/features/favorite/data/datasources/favorite_remote_data_source.dart';
import 'package:aqar/features/favorite/data/repositories/favorite_repository_impl.dart';
import 'package:aqar/features/favorite/domain/repositories/favorite_repository.dart';
import 'package:aqar/features/favorite/domain/usecases/add_to_favorite_usecase.dart';
import 'package:aqar/features/favorite/domain/usecases/remove_from_favorite_usecase.dart';
import 'package:aqar/features/favorite/domain/usecases/get_favorites_usecase.dart';
import 'package:aqar/features/favorite/presentation/bloc/favorite_bloc.dart';

// ========== RENT REQUEST IMPORTS ==========
import 'package:aqar/features/rent_request/data/datasources/rent_request_remote_datasource.dart';
import 'package:aqar/features/rent_request/data/repositories/rent_request_repository_impl.dart';
import 'package:aqar/features/rent_request/domain/repositories/rent_request_repository.dart';
import 'package:aqar/features/rent_request/domain/usecases/accept_rent_request_usecase.dart';
import 'package:aqar/features/rent_request/domain/usecases/cancel_rent_request_usecase.dart';
import 'package:aqar/features/rent_request/domain/usecases/create_rent_request_usecase.dart';
import 'package:aqar/features/rent_request/domain/usecases/get_received_requests_usecase.dart';
import 'package:aqar/features/rent_request/domain/usecases/get_sent_requests_usecase.dart';
import 'package:aqar/features/rent_request/domain/usecases/reject_rent_request_usecase.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';

final sl = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: false,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Core
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  sl.registerLazySingleton<InternetConnectionChecker>(() => InternetConnectionChecker.createInstance());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl<InternetConnectionChecker>()));
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<FlutterSecureStorage>()));

  // ========== AUTH ==========
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl<AuthRemoteDataSource>(), sl<FlutterSecureStorage>()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => RequestOtpUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));

  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl(),
        registerUseCase: sl(),
        logoutUseCase: sl(),
        forgotPasswordUseCase: sl(),
        resetPasswordUseCase: sl(),
        verifyOtpUseCase: sl(),
        requestOtpUseCase: sl(),
        getProfileUseCase: sl(),
        secureStorage: sl(),
      ));

  // ========== PROPERTY ==========
  sl.registerLazySingleton<PropertyRemoteDataSource>(() => PropertyRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<PropertyRepository>(() => PropertyRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetPropertiesUseCase(sl()));
  sl.registerLazySingleton(() => GetPropertyByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetMyPropertiesUseCase(sl()));
  sl.registerFactory(() => PropertyBloc(sl(), sl(), sl()));

  // ========== FAVORITE ==========
  sl.registerLazySingleton<FavoriteRemoteDataSource>(() => FavoriteRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<FavoriteRepository>(() => FavoriteRepositoryImpl(sl()));
  sl.registerLazySingleton(() => AddToFavoriteUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFromFavoriteUseCase(sl()));
  sl.registerLazySingleton(() => GetFavoritesUseCase(sl()));
  sl.registerFactory(() => FavoriteBloc(addToFavorite: sl(), removeFromFavorite: sl(), getFavorites: sl()));

  // ========== RENT REQUEST ==========
  sl.registerLazySingleton<RentRequestRemoteDataSource>(() => RentRequestRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<RentRequestRepository>(() => RentRequestRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetSentRequestsUseCase(sl()));
  sl.registerLazySingleton(() => GetReceivedRequestsUseCase(sl()));
  sl.registerLazySingleton(() => CreateRentRequestUseCase(sl()));
  sl.registerLazySingleton(() => AcceptRentRequestUseCase(sl()));
  sl.registerLazySingleton(() => RejectRentRequestUseCase(sl()));
  sl.registerLazySingleton(() => CancelRentRequestUseCase(sl()));
  sl.registerFactory(() => RentRequestBloc(
    getSentRequests: sl(),
    getReceivedRequests: sl(),
    createRequest: sl(),
    acceptRequest: sl(),
    rejectRequest: sl(),
    cancelRequest: sl(),
  ));

}
