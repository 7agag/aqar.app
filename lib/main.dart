import 'package:aqar/features/property/presentation/bloc/property_bloc.dart';
import 'package:aqar/features/property/presentation/bloc/property_event.dart';
import 'package:aqar/features/property/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/reset_password.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await configureDependencies();
  runApp(const AqarApp());
}

class AqarApp extends StatelessWidget {
  const AqarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<PropertyBloc>()
          ..add(GetPropertiesRequested()),),
      ],
      child: MaterialApp(
        title: 'AQAR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');

          if (uri.path == '/') {
            return MaterialPageRoute(builder: (_) => const HomePage());
          }

          if (uri.path == '/auth') {
            return MaterialPageRoute(builder: (_) => const AuthPage());
          }

          if (uri.path == '/home') {
            return MaterialPageRoute(builder: (_) => const HomePage());
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

          return MaterialPageRoute(builder: (_) => const AuthPage());
        },
      ),
    );
  }
}
