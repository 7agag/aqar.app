// lib/injection_container.dart

import 'package:aqar/core/network/network_info.dart';
import 'package:aqar/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:aqar/features/property/data/datasources/property_remote_datasource.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/services/notification_service.dart';
import 'package:aqar/core/network/socket_service.dart';
import 'package:aqar/core/services/escrow_service.dart';
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
import 'package:aqar/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:aqar/features/auth/domain/usecases/verify_reset_token_usecase.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:aqar/features/property/data/repositories/property_repository_impl.dart';
import 'package:aqar/features/property/domain/repositories/property_repository.dart';
import 'package:aqar/features/property/domain/usecases/get_properties_usecase.dart';
import 'package:aqar/features/property/domain/usecases/get_property_by_id_usecase.dart';
import 'package:aqar/features/property/domain/usecases/get_my_properties_usecase.dart';
import 'package:aqar/features/property/domain/usecases/add_property_usecase.dart';
import 'package:aqar/features/property/domain/usecases/edit_property_usecase.dart';
import 'package:aqar/features/property/domain/usecases/edit_property_images_usecase.dart';
import 'package:aqar/features/property/domain/usecases/delete_property_usecase.dart';
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart';

// ========== CHAT IMPORTS ==========
import 'package:aqar/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:aqar/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:aqar/features/chat/domain/repositories/chat_repository.dart';
import 'package:aqar/features/chat/domain/usecases/get_inbox_usecase.dart';
import 'package:aqar/features/chat/domain/usecases/get_chat_history_usecase.dart';
import 'package:aqar/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:aqar/features/chat/domain/usecases/mark_as_read_usecase.dart';
import 'package:aqar/features/chat/presentation/bloc/chat_bloc.dart';

// ========== FAVORITE IMPORTS ==========
import 'package:aqar/features/favorite/data/datasources/favorite_remote_data_source.dart';
import 'package:aqar/features/favorite/data/repositories/favorite_repository_impl.dart';
import 'package:aqar/features/favorite/domain/repositories/favorite_repository.dart';
import 'package:aqar/features/favorite/domain/usecases/add_to_favorite_usecase.dart';
import 'package:aqar/features/favorite/domain/usecases/remove_from_favorite_usecase.dart';
import 'package:aqar/features/favorite/domain/usecases/get_favorites_usecase.dart';
import 'package:aqar/features/favorite/domain/usecases/compare_favorites_usecase.dart';
import 'package:aqar/features/favorite/presentation/bloc/favorite_bloc.dart';

// ========== PAYMENT IMPORTS ==========
import 'package:aqar/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:aqar/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:aqar/features/payment/domain/repositories/payment_repository.dart';
import 'package:aqar/features/payment/domain/usecases/get_balance_usecase.dart';
import 'package:aqar/features/payment/domain/usecases/get_transactions_usecase.dart';
import 'package:aqar/features/payment/domain/usecases/get_payment_link_usecase.dart';
import 'package:aqar/features/payment/domain/usecases/request_withdrawal_usecase.dart';
import 'package:aqar/features/payment/domain/usecases/request_refund_usecase.dart';
import 'package:aqar/features/payment/domain/usecases/cancel_refund_request_usecase.dart';
import 'package:aqar/features/payment/domain/usecases/get_transfer_status_usecase.dart';
import 'package:aqar/features/payment/presentation/bloc/wallet_bloc.dart';

// ========== INVOICE IMPORTS ==========
import 'package:aqar/features/invoice/data/datasources/invoice_remote_datasource.dart';
import 'package:aqar/features/invoice/data/repositories/invoice_repository_impl.dart';
import 'package:aqar/features/invoice/domain/repositories/invoice_repository.dart';
import 'package:aqar/features/invoice/domain/usecases/get_renter_invoices_usecase.dart';
import 'package:aqar/features/invoice/domain/usecases/get_owner_invoices_usecase.dart';
import 'package:aqar/features/invoice/domain/usecases/get_invoice_stats_usecase.dart';
import 'package:aqar/features/invoice/presentation/bloc/invoice_bloc.dart';

// ========== LEASE IMPORTS ==========
import 'package:aqar/features/lease/data/datasources/lease_remote_datasource.dart';
import 'package:aqar/features/lease/data/repositories/lease_repository_impl.dart';
import 'package:aqar/features/lease/domain/repositories/lease_repository.dart';
import 'package:aqar/features/lease/domain/usecases/get_renter_leases_usecase.dart';
import 'package:aqar/features/lease/domain/usecases/get_owner_leases_usecase.dart';
import 'package:aqar/features/lease/domain/usecases/get_lease_detail_usecase.dart';
import 'package:aqar/features/lease/presentation/bloc/lease_bloc.dart';

// ========== NOTIFICATION IMPORTS ==========
import 'package:aqar/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:aqar/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:aqar/features/notifications/domain/repositories/notification_repository.dart';
import 'package:aqar/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:aqar/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:aqar/features/notifications/presentation/bloc/notification_bloc.dart';

// ========== SUBSCRIPTION IMPORTS ==========
import 'package:aqar/features/subscription/data/datasources/subscription_remote_data_source.dart';
import 'package:aqar/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:aqar/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:aqar/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:aqar/features/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:aqar/features/subscription/presentation/bloc/subscription_bloc.dart';

// ========== SPONSOR IMPORTS ==========
import 'package:aqar/features/sponsor/data/datasources/sponsor_remote_data_source.dart';
import 'package:aqar/features/sponsor/data/repositories/sponsor_repository_impl.dart';
import 'package:aqar/features/sponsor/domain/repositories/sponsor_repository.dart';
import 'package:aqar/features/sponsor/domain/usecases/create_sponsor_checkout_usecase.dart';
import 'package:aqar/features/sponsor/presentation/bloc/sponsor_bloc.dart';

// ========== REVIEW IMPORTS ==========
import 'package:aqar/features/review/data/datasources/review_remote_data_source.dart';
import 'package:aqar/features/review/data/repositories/review_repository_impl.dart';
import 'package:aqar/features/review/domain/repositories/review_repository.dart';
import 'package:aqar/features/review/domain/usecases/get_reviews_usecase.dart';
import 'package:aqar/features/review/domain/usecases/add_review_usecase.dart';
import 'package:aqar/features/review/presentation/bloc/review_bloc.dart';

// ========== PURCHASE REQUEST IMPORTS ==========
import 'package:aqar/features/purchase_request/data/datasources/purchase_request_remote_data_source.dart';
import 'package:aqar/features/purchase_request/data/repositories/purchase_request_repository_impl.dart';
import 'package:aqar/features/purchase_request/domain/repositories/purchase_request_repository.dart';
import 'package:aqar/features/purchase_request/domain/usecases/get_my_purchase_requests_usecase.dart';
import 'package:aqar/features/purchase_request/domain/usecases/get_received_purchase_requests_usecase.dart';
import 'package:aqar/features/purchase_request/domain/usecases/create_purchase_request_usecase.dart';
import 'package:aqar/features/purchase_request/domain/usecases/update_purchase_request_status_usecase.dart';
import 'package:aqar/features/purchase_request/domain/usecases/cancel_purchase_request_usecase.dart';
import 'package:aqar/features/purchase_request/domain/usecases/mark_property_sold_usecase.dart';
import 'package:aqar/features/purchase_request/presentation/bloc/purchase_request_bloc.dart';

// ========== RENT REQUEST IMPORTS ==========
import 'package:aqar/features/rent_request/data/datasources/rent_request_remote_datasource.dart';
import 'package:aqar/features/rent_request/data/repositories/rent_request_repository_impl.dart';
import 'package:aqar/features/rent_request/domain/repositories/rent_request_repository.dart';
import 'package:aqar/features/rent_request/domain/usecases/accept_rent_request_usecase.dart';
import 'package:aqar/features/rent_request/domain/usecases/cancel_rent_request_usecase.dart';
import 'package:aqar/features/rent_request/domain/usecases/create_rent_request_usecase.dart';
import 'package:aqar/features/rent_request/domain/usecases/get_received_requests_usecase.dart';
import 'package:aqar/features/rent_request/domain/usecases/get_rent_request_by_id_usecase.dart';
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
  sl.registerLazySingleton<SocketService>(() => SocketService(sl<FlutterSecureStorage>()));
  sl.registerLazySingleton<EscrowService>(() => EscrowService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // ========== AUTH ==========
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl<AuthRemoteDataSource>(), sl<FlutterSecureStorage>(), sl<NetworkInfo>()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => RequestOtpUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => VerifyResetTokenUseCase(sl()));

  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl(),
        registerUseCase: sl(),
        logoutUseCase: sl(),
        forgotPasswordUseCase: sl(),
        resetPasswordUseCase: sl(),
        verifyOtpUseCase: sl(),
        requestOtpUseCase: sl(),
        getProfileUseCase: sl(),
        updateProfileUseCase: sl(),
        changePasswordUseCase: sl(),
        verifyResetTokenUseCase: sl(),
        secureStorage: sl(),
      ));

  // ========== PROPERTY ==========
  sl.registerLazySingleton<PropertyRemoteDataSource>(() => PropertyRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<PropertyRepository>(() => PropertyRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetPropertiesUseCase(sl()));
  sl.registerLazySingleton(() => GetPropertyByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetMyPropertiesUseCase(sl()));
  sl.registerLazySingleton(() => AddPropertyUseCase(sl()));
  sl.registerLazySingleton(() => EditPropertyUseCase(sl()));
  sl.registerLazySingleton(() => EditPropertyImagesUseCase(sl()));
  sl.registerLazySingleton(() => DeletePropertyUseCase(sl()));
  sl.registerFactory(() => PropertyBloc(
    getProperties: sl(),
    getPropertyById: sl(),
    getMyProperties: sl(),
    addProperty: sl(),
    editProperty: sl(),
    editPropertyImages: sl(),
    deleteProperty: sl(),
  ));

  // ========== CHAT ==========
  sl.registerLazySingleton<ChatRemoteDataSource>(() => ChatRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetInboxUseCase(sl()));
  sl.registerLazySingleton(() => GetChatHistoryUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));
  sl.registerFactory(() => ChatBloc(
    getInbox: sl(),
    getChatHistory: sl(),
    sendMessage: sl(),
    markAsRead: sl(),
  ));

  // ========== FAVORITE ==========
  sl.registerLazySingleton<FavoriteRemoteDataSource>(() => FavoriteRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<FavoriteRepository>(() => FavoriteRepositoryImpl(sl()));
  sl.registerLazySingleton(() => AddToFavoriteUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFromFavoriteUseCase(sl()));
  sl.registerLazySingleton(() => GetFavoritesUseCase(sl()));
  sl.registerLazySingleton(() => CompareFavoritesUseCase(sl()));
  sl.registerFactory(() => FavoriteBloc(addToFavorite: sl(), removeFromFavorite: sl(), getFavorites: sl(), compareFavoritesUseCase: sl()));

  // ========== PAYMENT ==========
  sl.registerLazySingleton<PaymentRemoteDataSource>(() => PaymentRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetBalanceUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentLinkUseCase(sl()));
  sl.registerLazySingleton(() => RequestWithdrawalUseCase(sl()));
  sl.registerLazySingleton(() => RequestRefundUseCase(sl()));
  sl.registerLazySingleton(() => CancelRefundRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetTransferStatusUseCase(sl()));
  sl.registerFactory(() => WalletBloc(
    getBalance: sl(),
    getTransactions: sl(),
    requestWithdrawal: sl(),
  ));

  // ========== INVOICE ==========
  sl.registerLazySingleton<InvoiceRemoteDataSource>(() => InvoiceRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<InvoiceRepository>(() => InvoiceRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetRenterInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => GetOwnerInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoiceStatsUseCase(sl()));
  sl.registerFactory(() => InvoiceBloc(
    getRenterInvoices: sl(),
    getOwnerInvoices: sl(),
    getInvoiceStats: sl(),
  ));

  // ========== LEASE ==========
  sl.registerLazySingleton<LeaseRemoteDataSource>(() => LeaseRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<LeaseRepository>(() => LeaseRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetRenterLeasesUseCase(sl()));
  sl.registerLazySingleton(() => GetOwnerLeasesUseCase(sl()));
  sl.registerLazySingleton(() => GetLeaseDetailUseCase(sl()));
  sl.registerFactory(() => LeaseBloc(
    getRenterLeases: sl(),
    getOwnerLeases: sl(),
    getLeaseDetail: sl(),
  ));

  // ========== NOTIFICATIONS ==========
  sl.registerLazySingleton<NotificationRemoteDataSource>(() => NotificationRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  sl.registerFactory(() => NotificationBloc(
    getNotifications: sl(),
    markNotificationRead: sl(),
  ));

  // ========== SUBSCRIPTION ==========
  sl.registerLazySingleton<SubscriptionRemoteDataSource>(() => SubscriptionRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<SubscriptionRepository>(() => SubscriptionRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => CreateSubscriptionUseCase(sl()));
  sl.registerFactory(() => SubscriptionBloc(
    getSubscriptionUseCase: sl(),
    createSubscriptionUseCase: sl(),
  ));

  // ========== SPONSOR ==========
  sl.registerLazySingleton<SponsorRemoteDataSource>(() => SponsorRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<SponsorRepository>(() => SponsorRepositoryImpl(sl()));
  sl.registerLazySingleton(() => CreateSponsorCheckoutUseCase(sl()));
  sl.registerFactory(() => SponsorBloc(createCheckoutUseCase: sl()));

  // ========== REVIEW ==========
  sl.registerLazySingleton<ReviewRemoteDataSource>(() => ReviewRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetReviewsUseCase(sl()));
  sl.registerLazySingleton(() => AddReviewUseCase(sl()));
  sl.registerFactory(() => ReviewBloc(
    getReviewsUseCase: sl(),
    addReviewUseCase: sl(),
  ));

  // ========== PURCHASE REQUEST ==========
  sl.registerLazySingleton<PurchaseRequestRemoteDataSource>(() => PurchaseRequestRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<PurchaseRequestRepository>(() => PurchaseRequestRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMyPurchaseRequestsUseCase(sl()));
  sl.registerLazySingleton(() => GetReceivedPurchaseRequestsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePurchaseRequestUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePurchaseRequestStatusUseCase(sl()));
  sl.registerLazySingleton(() => CancelPurchaseRequestUseCase(sl()));
  sl.registerLazySingleton(() => MarkPropertySoldUseCase(sl()));
  sl.registerFactory(() => PurchaseRequestBloc(
    getMyRequestsUseCase: sl(),
    getReceivedRequestsUseCase: sl(),
    createRequestUseCase: sl(),
    updateStatusUseCase: sl(),
    cancelRequestUseCase: sl(),
    markPropertySoldUseCase: sl(),
  ));

  // ========== RENT REQUEST ==========
  sl.registerLazySingleton<RentRequestRemoteDataSource>(() => RentRequestRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<RentRequestRepository>(() => RentRequestRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetSentRequestsUseCase(sl()));
  sl.registerLazySingleton(() => GetReceivedRequestsUseCase(sl()));
  sl.registerLazySingleton(() => CreateRentRequestUseCase(sl()));
  sl.registerLazySingleton(() => AcceptRentRequestUseCase(sl()));
  sl.registerLazySingleton(() => RejectRentRequestUseCase(sl()));
  sl.registerLazySingleton(() => CancelRentRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetRentRequestByIdUseCase(sl()));
  sl.registerFactory(() => RentRequestBloc(
    getSentRequests: sl(),
    getReceivedRequests: sl(),
    createRequest: sl(),
    acceptRequest: sl(),
    rejectRequest: sl(),
    cancelRequest: sl(),
    getRentRequestByIdUseCase: sl(),
  ));

}
