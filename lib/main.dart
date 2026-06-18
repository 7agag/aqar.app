// lib/main.dart

import 'package:aqar/core/theme/app_theme.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_event.dart';
import 'package:aqar/features/auth/presentation/pages/auth_page.dart';
import 'package:aqar/features/auth/presentation/pages/reset_password.dart';
import 'package:aqar/features/favorite/presentation/bloc/favorite_bloc.dart';
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart';
import 'package:aqar/features/property/presentation/pages/home_page.dart';
import 'package:aqar/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await configureDependencies();

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

class AqarApp extends StatelessWidget {
  const AqarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) {
            final bloc = sl<AuthBloc>();
            bloc.add(CheckAuthStatus());
            return bloc;
          },
        ),
        BlocProvider<PropertyBloc>(
          create: (context) => sl<PropertyBloc>(),
        ),
        BlocProvider<FavoriteBloc>(
          create: (context) => sl<FavoriteBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'AQAR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              physics: const BouncingScrollPhysics(),
            ),
            child: child!,
          );
        },
        initialRoute: '/',
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          if (uri.path == '/' || uri.path == '/home') {
            return MaterialPageRoute(builder: (_) => const HomePage(), settings: settings);
          }
          if (uri.path == '/auth') {
            return MaterialPageRoute(builder: (_) => const AuthPage(), settings: settings);
          }
          if (uri.pathSegments.length >= 2 &&
              uri.pathSegments[0] == 'auth' &&
              uri.pathSegments[1] == 'reset-password') {
            final token = uri.pathSegments.length >= 3 ? uri.pathSegments[2] : null;
            return MaterialPageRoute(
              builder: (_) => ResetPasswordPage(token: token),
              settings: settings,
            );
          }
          return MaterialPageRoute(builder: (_) => const AuthPage(), settings: settings);
        },
        themeMode: ThemeMode.light,
      ),
    );
  }
}
