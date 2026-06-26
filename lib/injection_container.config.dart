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
import 'package:aqar/features/auth/domain/usecases/change_password_usecase.dart'
    as _i359;
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
import 'package:aqar/features/auth/domain/usecases/update_profile_usecase.dart'
    as _i803;
import 'package:aqar/features/auth/domain/usecases/verify_otp_usecase.dart'
    as _i806;
import 'package:aqar/features/auth/domain/usecases/verify_reset_token_usecase.dart'
    as _i380;
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart' as _i749;
import 'package:aqar/features/chat/data/datasources/chat_remote_datasource.dart'
    as _i483;
import 'package:aqar/features/chat/data/repositories/chat_repository_impl.dart'
    as _i792;
import 'package:aqar/features/chat/domain/repositories/chat_repository.dart'
    as _i255;
import 'package:aqar/features/chat/domain/usecases/get_chat_history_usecase.dart'
    as _i760;
import 'package:aqar/features/chat/domain/usecases/get_inbox_usecase.dart'
    as _i396;
import 'package:aqar/features/chat/domain/usecases/mark_as_read_usecase.dart'
    as _i295;
import 'package:aqar/features/chat/domain/usecases/send_message_usecase.dart'
    as _i734;
import 'package:aqar/features/chat/presentation/bloc/chat_bloc.dart' as _i272;
import 'package:aqar/features/favorite/data/datasources/favorite_remote_data_source.dart'
    as _i352;
import 'package:aqar/features/favorite/data/repositories/favorite_repository_impl.dart'
    as _i913;
import 'package:aqar/features/favorite/domain/repositories/favorite_repository.dart'
    as _i419;
import 'package:aqar/features/favorite/domain/usecases/add_to_favorite_usecase.dart'
    as _i617;
import 'package:aqar/features/favorite/domain/usecases/compare_favorites_usecase.dart'
    as _i834;
import 'package:aqar/features/favorite/domain/usecases/get_favorites_usecase.dart'
    as _i524;
import 'package:aqar/features/favorite/domain/usecases/remove_from_favorite_usecase.dart'
    as _i963;
import 'package:aqar/features/favorite/presentation/bloc/favorite_bloc.dart'
    as _i717;
import 'package:aqar/features/invoice/data/datasources/invoice_remote_datasource.dart'
    as _i791;
import 'package:aqar/features/invoice/data/repositories/invoice_repository_impl.dart'
    as _i331;
import 'package:aqar/features/invoice/domain/repositories/invoice_repository.dart'
    as _i200;
import 'package:aqar/features/invoice/domain/usecases/get_invoice_stats_usecase.dart'
    as _i962;
import 'package:aqar/features/invoice/domain/usecases/get_owner_invoices_usecase.dart'
    as _i98;
import 'package:aqar/features/invoice/domain/usecases/get_renter_invoices_usecase.dart'
    as _i600;
import 'package:aqar/features/invoice/presentation/bloc/invoice_bloc.dart'
    as _i1005;
import 'package:aqar/features/lease/data/datasources/lease_remote_datasource.dart'
    as _i986;
import 'package:aqar/features/lease/data/repositories/lease_repository_impl.dart'
    as _i240;
import 'package:aqar/features/lease/domain/repositories/lease_repository.dart'
    as _i726;
import 'package:aqar/features/lease/domain/usecases/get_lease_detail_usecase.dart'
    as _i67;
import 'package:aqar/features/lease/domain/usecases/get_owner_leases_usecase.dart'
    as _i318;
import 'package:aqar/features/lease/domain/usecases/get_renter_leases_usecase.dart'
    as _i113;
import 'package:aqar/features/lease/presentation/bloc/lease_bloc.dart' as _i647;
import 'package:aqar/features/notifications/data/datasources/notification_remote_datasource.dart'
    as _i129;
import 'package:aqar/features/notifications/data/repositories/notification_repository_impl.dart'
    as _i416;
import 'package:aqar/features/notifications/domain/repositories/notification_repository.dart'
    as _i457;
import 'package:aqar/features/notifications/domain/usecases/get_notifications_usecase.dart'
    as _i955;
import 'package:aqar/features/notifications/domain/usecases/mark_notification_read_usecase.dart'
    as _i755;
import 'package:aqar/features/notifications/presentation/bloc/notification_bloc.dart'
    as _i456;
import 'package:aqar/features/payment/data/datasources/payment_remote_datasource.dart'
    as _i527;
import 'package:aqar/features/payment/data/repositories/payment_repository_impl.dart'
    as _i1032;
import 'package:aqar/features/payment/domain/repositories/payment_repository.dart'
    as _i296;
import 'package:aqar/features/payment/domain/usecases/cancel_refund_request_usecase.dart'
    as _i490;
import 'package:aqar/features/payment/domain/usecases/get_balance_usecase.dart'
    as _i941;
import 'package:aqar/features/payment/domain/usecases/get_payment_link_usecase.dart'
    as _i546;
import 'package:aqar/features/payment/domain/usecases/get_transactions_usecase.dart'
    as _i662;
import 'package:aqar/features/payment/domain/usecases/get_transfer_status_usecase.dart'
    as _i524;
import 'package:aqar/features/payment/domain/usecases/request_refund_usecase.dart'
    as _i454;
import 'package:aqar/features/payment/domain/usecases/request_withdrawal_usecase.dart'
    as _i521;
import 'package:aqar/features/payment/presentation/bloc/wallet_bloc.dart'
    as _i759;
import 'package:aqar/features/property/data/datasources/property_remote_datasource.dart'
    as _i359;
import 'package:aqar/features/property/data/repositories/property_repository_impl.dart'
    as _i985;
import 'package:aqar/features/property/domain/repositories/property_repository.dart'
    as _i268;
import 'package:aqar/features/property/domain/usecases/add_property_usecase.dart'
    as _i92;
import 'package:aqar/features/property/domain/usecases/delete_property_usecase.dart'
    as _i349;
import 'package:aqar/features/property/domain/usecases/edit_property_images_usecase.dart'
    as _i818;
import 'package:aqar/features/property/domain/usecases/edit_property_usecase.dart'
    as _i708;
import 'package:aqar/features/property/domain/usecases/get_booked_dates_usecase.dart'
    as _i483;
import 'package:aqar/features/property/domain/usecases/get_my_properties_usecase.dart'
    as _i29;
import 'package:aqar/features/property/domain/usecases/get_properties_usecase.dart'
    as _i247;
import 'package:aqar/features/property/domain/usecases/get_property_by_id_usecase.dart'
    as _i240;
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart'
    as _i411;
import 'package:aqar/features/purchase_request/domain/repositories/purchase_request_repository.dart'
    as _i328;
import 'package:aqar/features/purchase_request/domain/usecases/cancel_purchase_request_usecase.dart'
    as _i233;
import 'package:aqar/features/purchase_request/domain/usecases/create_purchase_request_usecase.dart'
    as _i961;
import 'package:aqar/features/purchase_request/domain/usecases/get_my_purchase_requests_usecase.dart'
    as _i543;
import 'package:aqar/features/purchase_request/domain/usecases/get_received_purchase_requests_usecase.dart'
    as _i107;
import 'package:aqar/features/purchase_request/domain/usecases/mark_property_sold_usecase.dart'
    as _i378;
import 'package:aqar/features/purchase_request/domain/usecases/update_purchase_request_status_usecase.dart'
    as _i1053;
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
import 'package:aqar/features/rent_request/domain/usecases/get_rent_request_by_id_usecase.dart'
    as _i653;
import 'package:aqar/features/rent_request/domain/usecases/get_sent_requests_usecase.dart'
    as _i994;
import 'package:aqar/features/rent_request/domain/usecases/reject_rent_request_usecase.dart'
    as _i1015;
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart'
    as _i615;
import 'package:aqar/features/review/domain/repositories/review_repository.dart'
    as _i105;
import 'package:aqar/features/review/domain/usecases/add_review_usecase.dart'
    as _i190;
import 'package:aqar/features/review/domain/usecases/get_reviews_usecase.dart'
    as _i366;
import 'package:aqar/features/subscription/domain/repositories/subscription_repository.dart'
    as _i539;
import 'package:aqar/features/subscription/domain/usecases/create_subscription_usecase.dart'
    as _i345;
import 'package:aqar/features/subscription/domain/usecases/get_subscription_usecase.dart'
    as _i766;
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
    gh.factory<_i791.InvoiceRemoteDataSource>(
        () => _i791.InvoiceRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i233.CancelPurchaseRequestUseCase>(() =>
        _i233.CancelPurchaseRequestUseCase(
            gh<_i328.PurchaseRequestRepository>()));
    gh.factory<_i961.CreatePurchaseRequestUseCase>(() =>
        _i961.CreatePurchaseRequestUseCase(
            gh<_i328.PurchaseRequestRepository>()));
    gh.factory<_i543.GetMyPurchaseRequestsUseCase>(() =>
        _i543.GetMyPurchaseRequestsUseCase(
            gh<_i328.PurchaseRequestRepository>()));
    gh.factory<_i107.GetReceivedPurchaseRequestsUseCase>(() =>
        _i107.GetReceivedPurchaseRequestsUseCase(
            gh<_i328.PurchaseRequestRepository>()));
    gh.factory<_i378.MarkPropertySoldUseCase>(() =>
        _i378.MarkPropertySoldUseCase(gh<_i328.PurchaseRequestRepository>()));
    gh.factory<_i1053.UpdatePurchaseRequestStatusUseCase>(() =>
        _i1053.UpdatePurchaseRequestStatusUseCase(
            gh<_i328.PurchaseRequestRepository>()));
    gh.factory<_i763.NetworkInfo>(
        () => _i763.NetworkInfoImpl(gh<_i973.InternetConnectionChecker>()));
    gh.factory<_i190.AddReviewUseCase>(
        () => _i190.AddReviewUseCase(gh<_i105.ReviewRepository>()));
    gh.factory<_i366.GetReviewsUseCase>(
        () => _i366.GetReviewsUseCase(gh<_i105.ReviewRepository>()));
    gh.factory<_i986.LeaseRemoteDataSource>(
        () => _i986.LeaseRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i527.PaymentRemoteDataSource>(
        () => _i527.PaymentRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i483.ChatRemoteDataSource>(
        () => _i483.ChatRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i359.PropertyRemoteDataSource>(
        () => _i359.PropertyRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i726.LeaseRepository>(
        () => _i240.LeaseRepositoryImpl(gh<_i986.LeaseRemoteDataSource>()));
    gh.factory<_i129.NotificationRemoteDataSource>(
        () => _i129.NotificationRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i352.FavoriteRemoteDataSource>(
        () => _i352.FavoriteRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i144.AuthRepository>(() => _i1061.AuthRepositoryImpl(
          gh<_i898.AuthRemoteDataSource>(),
          gh<_i558.FlutterSecureStorage>(),
          gh<_i763.NetworkInfo>(),
        ));
    gh.factory<_i345.CreateSubscriptionUseCase>(() =>
        _i345.CreateSubscriptionUseCase(gh<_i539.SubscriptionRepository>()));
    gh.factory<_i766.GetSubscriptionUseCase>(
        () => _i766.GetSubscriptionUseCase(gh<_i539.SubscriptionRepository>()));
    gh.factory<_i866.RentRequestRemoteDataSource>(
        () => _i866.RentRequestRemoteDataSourceImpl(gh<_i164.ApiClient>()));
    gh.factory<_i296.PaymentRepository>(() =>
        _i1032.PaymentRepositoryImpl(gh<_i527.PaymentRemoteDataSource>()));
    gh.factory<_i268.PropertyRepository>(() =>
        _i985.PropertyRepositoryImpl(gh<_i359.PropertyRemoteDataSource>()));
    gh.factory<_i359.ChangePasswordUseCase>(
        () => _i359.ChangePasswordUseCase(gh<_i144.AuthRepository>()));
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
    gh.factory<_i803.UpdateProfileUseCase>(
        () => _i803.UpdateProfileUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i806.VerifyOtpUseCase>(
        () => _i806.VerifyOtpUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i380.VerifyResetTokenUseCase>(
        () => _i380.VerifyResetTokenUseCase(gh<_i144.AuthRepository>()));
    gh.factory<_i255.ChatRepository>(
        () => _i792.ChatRepositoryImpl(gh<_i483.ChatRemoteDataSource>()));
    gh.factory<_i200.InvoiceRepository>(
        () => _i331.InvoiceRepositoryImpl(gh<_i791.InvoiceRemoteDataSource>()));
    gh.factory<_i749.AuthBloc>(() => _i749.AuthBloc(
          loginUseCase: gh<_i376.LoginUseCase>(),
          registerUseCase: gh<_i669.RegisterUseCase>(),
          logoutUseCase: gh<_i950.LogoutUseCase>(),
          forgotPasswordUseCase: gh<_i394.ForgotPasswordUseCase>(),
          resetPasswordUseCase: gh<_i597.ResetPasswordUseCase>(),
          verifyOtpUseCase: gh<_i806.VerifyOtpUseCase>(),
          requestOtpUseCase: gh<_i352.RequestOtpUseCase>(),
          getProfileUseCase: gh<_i925.GetProfileUseCase>(),
          updateProfileUseCase: gh<_i803.UpdateProfileUseCase>(),
          changePasswordUseCase: gh<_i359.ChangePasswordUseCase>(),
          verifyResetTokenUseCase: gh<_i380.VerifyResetTokenUseCase>(),
          secureStorage: gh<_i558.FlutterSecureStorage>(),
        ));
    gh.factory<_i67.GetLeaseDetailUseCase>(
        () => _i67.GetLeaseDetailUseCase(gh<_i726.LeaseRepository>()));
    gh.factory<_i318.GetOwnerLeasesUseCase>(
        () => _i318.GetOwnerLeasesUseCase(gh<_i726.LeaseRepository>()));
    gh.factory<_i113.GetRenterLeasesUseCase>(
        () => _i113.GetRenterLeasesUseCase(gh<_i726.LeaseRepository>()));
    gh.factory<_i490.CancelRefundRequestUseCase>(
        () => _i490.CancelRefundRequestUseCase(gh<_i296.PaymentRepository>()));
    gh.factory<_i941.GetBalanceUseCase>(
        () => _i941.GetBalanceUseCase(gh<_i296.PaymentRepository>()));
    gh.factory<_i546.GetPaymentLinkUseCase>(
        () => _i546.GetPaymentLinkUseCase(gh<_i296.PaymentRepository>()));
    gh.factory<_i662.GetTransactionsUseCase>(
        () => _i662.GetTransactionsUseCase(gh<_i296.PaymentRepository>()));
    gh.factory<_i524.GetTransferStatusUseCase>(
        () => _i524.GetTransferStatusUseCase(gh<_i296.PaymentRepository>()));
    gh.factory<_i454.RequestRefundUseCase>(
        () => _i454.RequestRefundUseCase(gh<_i296.PaymentRepository>()));
    gh.factory<_i521.RequestWithdrawalUseCase>(
        () => _i521.RequestWithdrawalUseCase(gh<_i296.PaymentRepository>()));
    gh.factory<_i92.AddPropertyUseCase>(
        () => _i92.AddPropertyUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i349.DeletePropertyUseCase>(
        () => _i349.DeletePropertyUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i818.EditPropertyImagesUseCase>(
        () => _i818.EditPropertyImagesUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i708.EditPropertyUseCase>(
        () => _i708.EditPropertyUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i483.GetBookedDatesUseCase>(
        () => _i483.GetBookedDatesUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i29.GetMyPropertiesUseCase>(
        () => _i29.GetMyPropertiesUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i247.GetPropertiesUseCase>(
        () => _i247.GetPropertiesUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i240.GetPropertyByIdUseCase>(
        () => _i240.GetPropertyByIdUseCase(gh<_i268.PropertyRepository>()));
    gh.factory<_i962.GetInvoiceStatsUseCase>(
        () => _i962.GetInvoiceStatsUseCase(gh<_i200.InvoiceRepository>()));
    gh.factory<_i98.GetOwnerInvoicesUseCase>(
        () => _i98.GetOwnerInvoicesUseCase(gh<_i200.InvoiceRepository>()));
    gh.factory<_i600.GetRenterInvoicesUseCase>(
        () => _i600.GetRenterInvoicesUseCase(gh<_i200.InvoiceRepository>()));
    gh.factory<_i1005.InvoiceBloc>(() => _i1005.InvoiceBloc(
          getRenterInvoices: gh<_i600.GetRenterInvoicesUseCase>(),
          getOwnerInvoices: gh<_i98.GetOwnerInvoicesUseCase>(),
          getInvoiceStats: gh<_i962.GetInvoiceStatsUseCase>(),
        ));
    gh.factory<_i647.LeaseBloc>(() => _i647.LeaseBloc(
          getRenterLeases: gh<_i113.GetRenterLeasesUseCase>(),
          getOwnerLeases: gh<_i318.GetOwnerLeasesUseCase>(),
          getLeaseDetail: gh<_i67.GetLeaseDetailUseCase>(),
        ));
    gh.factory<_i719.RentRequestRepository>(() =>
        _i964.RentRequestRepositoryImpl(
            gh<_i866.RentRequestRemoteDataSource>()));
    gh.factory<_i457.NotificationRepository>(() =>
        _i416.NotificationRepositoryImpl(
            gh<_i129.NotificationRemoteDataSource>()));
    gh.factory<_i411.PropertyBloc>(() => _i411.PropertyBloc(
          getProperties: gh<_i247.GetPropertiesUseCase>(),
          getPropertyById: gh<_i240.GetPropertyByIdUseCase>(),
          getMyProperties: gh<_i29.GetMyPropertiesUseCase>(),
          addProperty: gh<_i92.AddPropertyUseCase>(),
          editProperty: gh<_i708.EditPropertyUseCase>(),
          editPropertyImages: gh<_i818.EditPropertyImagesUseCase>(),
          deleteProperty: gh<_i349.DeletePropertyUseCase>(),
        ));
    gh.factory<_i760.GetChatHistoryUseCase>(
        () => _i760.GetChatHistoryUseCase(gh<_i255.ChatRepository>()));
    gh.factory<_i396.GetInboxUseCase>(
        () => _i396.GetInboxUseCase(gh<_i255.ChatRepository>()));
    gh.factory<_i295.MarkAsReadUseCase>(
        () => _i295.MarkAsReadUseCase(gh<_i255.ChatRepository>()));
    gh.factory<_i734.SendMessageUseCase>(
        () => _i734.SendMessageUseCase(gh<_i255.ChatRepository>()));
    gh.factory<_i419.FavoriteRepository>(() =>
        _i913.FavoriteRepositoryImpl(gh<_i352.FavoriteRemoteDataSource>()));
    gh.factory<_i272.ChatBloc>(() => _i272.ChatBloc(
          getInbox: gh<_i396.GetInboxUseCase>(),
          getChatHistory: gh<_i760.GetChatHistoryUseCase>(),
          sendMessage: gh<_i734.SendMessageUseCase>(),
          markAsRead: gh<_i295.MarkAsReadUseCase>(),
        ));
    gh.factory<_i721.AcceptRentRequestUseCase>(() =>
        _i721.AcceptRentRequestUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i363.CancelRentRequestUseCase>(() =>
        _i363.CancelRentRequestUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i1058.CreateRentRequestUseCase>(() =>
        _i1058.CreateRentRequestUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i47.GetReceivedRequestsUseCase>(() =>
        _i47.GetReceivedRequestsUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i653.GetRentRequestByIdUseCase>(() =>
        _i653.GetRentRequestByIdUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i994.GetSentRequestsUseCase>(
        () => _i994.GetSentRequestsUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i1015.RejectRentRequestUseCase>(() =>
        _i1015.RejectRentRequestUseCase(gh<_i719.RentRequestRepository>()));
    gh.factory<_i759.WalletBloc>(() => _i759.WalletBloc(
          getBalance: gh<_i941.GetBalanceUseCase>(),
          getTransactions: gh<_i662.GetTransactionsUseCase>(),
          requestWithdrawal: gh<_i521.RequestWithdrawalUseCase>(),
        ));
    gh.factory<_i615.RentRequestBloc>(() => _i615.RentRequestBloc(
          getSentRequests: gh<_i994.GetSentRequestsUseCase>(),
          getReceivedRequests: gh<_i47.GetReceivedRequestsUseCase>(),
          createRequest: gh<_i1058.CreateRentRequestUseCase>(),
          acceptRequest: gh<_i721.AcceptRentRequestUseCase>(),
          rejectRequest: gh<_i1015.RejectRentRequestUseCase>(),
          cancelRequest: gh<_i363.CancelRentRequestUseCase>(),
          getRentRequestByIdUseCase: gh<_i653.GetRentRequestByIdUseCase>(),
        ));
    gh.factory<_i955.GetNotificationsUseCase>(() =>
        _i955.GetNotificationsUseCase(gh<_i457.NotificationRepository>()));
    gh.factory<_i755.MarkNotificationReadUseCase>(() =>
        _i755.MarkNotificationReadUseCase(gh<_i457.NotificationRepository>()));
    gh.factory<_i456.NotificationBloc>(() => _i456.NotificationBloc(
          getNotifications: gh<_i955.GetNotificationsUseCase>(),
          markNotificationRead: gh<_i755.MarkNotificationReadUseCase>(),
        ));
    gh.factory<_i617.AddToFavoriteUseCase>(
        () => _i617.AddToFavoriteUseCase(gh<_i419.FavoriteRepository>()));
    gh.factory<_i834.CompareFavoritesUseCase>(
        () => _i834.CompareFavoritesUseCase(gh<_i419.FavoriteRepository>()));
    gh.factory<_i524.GetFavoritesUseCase>(
        () => _i524.GetFavoritesUseCase(gh<_i419.FavoriteRepository>()));
    gh.factory<_i963.RemoveFromFavoriteUseCase>(
        () => _i963.RemoveFromFavoriteUseCase(gh<_i419.FavoriteRepository>()));
    gh.factory<_i717.FavoriteBloc>(() => _i717.FavoriteBloc(
          addToFavorite: gh<_i617.AddToFavoriteUseCase>(),
          removeFromFavorite: gh<_i963.RemoveFromFavoriteUseCase>(),
          getFavorites: gh<_i524.GetFavoritesUseCase>(),
          compareFavoritesUseCase: gh<_i834.CompareFavoritesUseCase>(),
        ));
    return this;
  }
}

class _$InjectionModule extends _i193.InjectionModule {}
