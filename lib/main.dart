// lib/main.dart

import 'package:aqar/core/localization/app_strings.dart';
import 'package:aqar/core/network/socket_service.dart';
import 'package:aqar/core/services/escrow_service.dart';
import 'package:aqar/core/services/notification_service.dart';
import 'package:aqar/core/theme/app_theme.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_event.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_state.dart';
import 'package:aqar/features/auth/presentation/pages/auth_page.dart';
import 'package:aqar/features/auth/presentation/pages/reset_password.dart';
import 'package:aqar/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:aqar/features/favorite/presentation/bloc/favorite_bloc.dart';
import 'package:aqar/features/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:aqar/features/lease/presentation/bloc/lease_bloc.dart';
import 'package:aqar/features/payment/presentation/bloc/wallet_bloc.dart';
import 'package:aqar/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:aqar/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:aqar/features/purchase_request/presentation/bloc/purchase_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/review/presentation/bloc/review_bloc.dart';
import 'package:aqar/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart';
import 'package:aqar/features/property/presentation/pages/home_page.dart';
import 'package:aqar/features/splash/presentation/pages/splash_page.dart';
import 'package:aqar/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await di.configureDependencies();

  final prefs = await SharedPreferences.getInstance();
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

class _AqarAppState extends State<AqarApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen(_handleDeepLink);
    _appLinks.getInitialLink().then(_handleDeepLink);
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;
    if (uri.host == 'payment-callback') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _navigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('نتيجة الدفع'),
                centerTitle: true,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 72, color: Color(0xFF27AE60)),
                      const SizedBox(height: 20),
                      const Text(
                        'تمت عملية الدفع بنجاح',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'رقم العملية: ${uri.queryParameters['transactionId'] ?? 'N/A'}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2744),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('العودة',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
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
        BlocProvider<PaymentBloc>(
          create: (context) => di.sl<PaymentBloc>(),
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
          } else if (state is AuthUnauthenticated) {
            socketService.disconnect();
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
