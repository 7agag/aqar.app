// lib/main.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:aqar/core/localization/app_strings.dart';
import 'package:aqar/core/network/socket_service.dart';
import 'package:aqar/core/services/app_permission_service.dart';
import 'package:aqar/core/services/escrow_service.dart';
import 'package:aqar/core/services/notification_service.dart';
import 'package:aqar/core/theme/app_theme.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_event.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_state.dart';
import 'package:aqar/features/auth/presentation/pages/auth_page.dart';
import 'package:aqar/features/auth/presentation/pages/reset_password.dart';
import 'package:aqar/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:aqar/features/chat/presentation/pages/chat_list_page.dart';
import 'package:aqar/features/favorite/presentation/bloc/favorite_bloc.dart';
import 'package:aqar/features/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:aqar/features/lease/presentation/bloc/lease_bloc.dart';
import 'package:aqar/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:aqar/features/notifications/presentation/bloc/notification_event.dart';
import 'package:aqar/features/notifications/presentation/pages/notifications_page.dart';
import 'package:aqar/features/payment/presentation/bloc/wallet_bloc.dart';
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart';
import 'package:aqar/features/property/presentation/pages/home_page.dart';
import 'package:aqar/features/property/presentation/pages/my_properties_page.dart';
import 'package:aqar/features/purchase_request/presentation/bloc/purchase_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/pages/rent_request_detail_page.dart';
import 'package:aqar/features/rent_request/presentation/pages/rent_requests_page.dart';
import 'package:aqar/features/review/presentation/bloc/review_bloc.dart';
import 'package:aqar/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:aqar/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:aqar/features/payment/presentation/pages/payment_result_screen.dart';
import 'package:aqar/features/payment/presentation/pages/invoices_page.dart';
import 'package:aqar/features/splash/presentation/pages/splash_page.dart';
import 'package:aqar/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar/features/payment/presentation/mixins/payment_resume_verifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await di.configureDependencies();

  final prefs = await SharedPreferences.getInstance();
  di.sl.registerLazySingleton<SharedPreferences>(() => prefs);

  final savedLocale = prefs.getString('locale') ?? '';
  if (savedLocale.isNotEmpty) {
    AppStrings.locale = savedLocale;
  } else {
    final deviceLocale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    AppStrings.locale = deviceLocale == 'ar' ? 'ar' : 'en';
  }

  if (kReleaseMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log(
        'Flutter Error: ${details.exception}',
        name: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
  }

  runApp(const AqarApp());
}

class AqarApp extends StatefulWidget {
  const AqarApp({super.key});

  @override
  State<AqarApp> createState() => _AqarAppState();
}

class _AqarAppState extends State<AqarApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  final _resumeVerifier = PaymentResumeVerifier();
  StreamSubscription<Map<String, dynamic>>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen(_handleDeepLink);
    _appLinks.getInitialLink().then(_handleDeepLink);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppPermissionService.requestStartupPermissions();
    });
    di.sl<NotificationService>().onNotificationTap = _onNotificationTap;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeVerifier.verifyOnResume(_navigatorKey);
    }
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme == 'aqar.jovek' && uri.host == 'payment-callback') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _navigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        final status = uri.queryParameters['status'] ?? 'success';
        final pid = int.tryParse(uri.queryParameters['propertyId'] ?? '') ?? 0;
        final type = uri.queryParameters['type'] ?? 'subscription';
        Navigator.of(ctx).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => PaymentResultScreen(
              paymentStatus: status,
              propertyId: pid,
              type: type,
              amount: uri.queryParameters['amount'],
            ),
          ),
          (route) => route.isFirst,
        );
      });
    }
  }

  void _onNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final ctx = _navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      );
      return;
    }

    final type = data['type'] as String? ?? '';
    final metadata = data['metadata'] as Map<String, dynamic>?;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      final navigator = Navigator.of(context);

      switch (type) {
        case 'chat':
          navigator.push(
            MaterialPageRoute(builder: (_) => const ChatListPage()),
          );
        case 'invoice':
          navigator.push(
            MaterialPageRoute(builder: (_) => const InvoicesPage()),
          );
        case 'rent':
          final requestId = metadata?['request_id'] as String?;
          if (requestId != null && requestId.isNotEmpty) {
            navigator.push(
              MaterialPageRoute(
                builder: (_) => RentRequestDetailPage(
                  requestId: requestId,
                  isSent: true,
                ),
              ),
            );
          } else {
            navigator.push(
              MaterialPageRoute(builder: (_) => const MyRequestsPage()),
            );
          }
        case 'property_rejection':
        case 'property_acception':
          navigator.push(
            MaterialPageRoute(builder: (_) => const MyPropertiesPage()),
          );
        default:
          navigator.push(
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          );
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _appLinks = AppLinks();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) {
            final bloc = di.sl<AuthBloc>();
            bloc.add(CheckAuthStatus());
            return bloc;
          },
        ),
        BlocProvider<PropertyBloc>(
          create: (context) => di.sl<PropertyBloc>(),
        ),
        BlocProvider<FavoriteBloc>(
          create: (context) => di.sl<FavoriteBloc>(),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => di.sl<ChatBloc>(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => di.sl<NotificationBloc>(),
        ),
        BlocProvider<LeaseBloc>(
          create: (context) => di.sl<LeaseBloc>(),
        ),
        BlocProvider<InvoiceBloc>(
          create: (context) => di.sl<InvoiceBloc>(),
        ),
        BlocProvider<WalletBloc>(
          create: (context) => di.sl<WalletBloc>(),
        ),
        BlocProvider<PurchaseRequestBloc>(
          create: (context) => di.sl<PurchaseRequestBloc>(),
        ),
        BlocProvider<RentRequestBloc>(
          create: (context) => di.sl<RentRequestBloc>(),
        ),
        BlocProvider<ReviewBloc>(
          create: (context) => di.sl<ReviewBloc>(),
        ),
        BlocProvider<SubscriptionBloc>(
          create: (context) => di.sl<SubscriptionBloc>(),
        ),
        BlocProvider<AiBloc>(
          create: (context) => di.sl<AiBloc>(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          final socketService = di.sl<SocketService>();
          final escrowService = di.sl<EscrowService>();
          final notificationService = di.sl<NotificationService>();
          if (state is AuthProfileLoaded) {
            socketService.connect();
            escrowService.init();
            notificationService.init();
            context.read<NotificationBloc>().add(const GetNotificationsRequested());
            _notificationSub?.cancel();
            _notificationSub = socketService.onNotification.listen((data) async {
              final prefs = await SharedPreferences.getInstance();
              if (prefs.getBool('notifications_enabled') ?? true) {
                final title = data['notification_title'] as String? ?? 'New Notification';
                final body = data['notification_body'] as String? ?? '';
                final eventType = data['event_type'] as String? ?? '';
                final metadata = data['metadata'];
                final payload = jsonEncode({
                  'type': eventType,
                  if (metadata != null) 'metadata': metadata,
                });
                notificationService.showNotification(
                  title: title,
                  body: body,
                  payload: payload,
                );
              }
            });
          } else if (state is AuthUnauthenticated) {
            _notificationSub?.cancel();
            _notificationSub = null;
            socketService.disconnect();
            _navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthPage()),
              (route) => route.isFirst,
            );
          }
        },
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'AQAR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: Locale(AppStrings.locale),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supported) {
            if (locale != null && supported.contains(locale)) {
              AppStrings.locale = locale.languageCode;
              return locale;
            }
            AppStrings.locale = 'en';
            return const Locale('en');
          },
          builder: (context, child) {
            return Directionality(
              textDirection:
                  AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  physics: const BouncingScrollPhysics(),
                ),
                child: child!,
              ),
            );
          },
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '/');
            if (uri.path == '/') {
              return MaterialPageRoute(
                  builder: (_) => const SplashPage(), settings: settings);
            }
            if (uri.path == '/home') {
              return MaterialPageRoute(
                  builder: (_) => const HomePage(), settings: settings);
            }
            if (uri.path == '/auth') {
              return MaterialPageRoute(
                  builder: (_) => const AuthPage(), settings: settings);
            }
            if (uri.pathSegments.length >= 2 &&
                uri.pathSegments[0] == 'auth' &&
                uri.pathSegments[1] == 'reset-password') {
              final token =
                  uri.pathSegments.length >= 3 ? uri.pathSegments[2] : null;
              return MaterialPageRoute(
                builder: (_) => ResetPasswordPage(token: token),
                settings: settings,
              );
            }
            return MaterialPageRoute(
                builder: (_) => const AuthPage(), settings: settings);
          },
          themeMode: ThemeMode.light,
        ),
      ),
    );
  }
}
