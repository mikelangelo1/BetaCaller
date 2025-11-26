import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beta_caller/providers/auth_provider.dart';
import 'package:beta_caller/providers/call_provider.dart';
import 'package:beta_caller/providers/contact_provider.dart';
import 'package:beta_caller/providers/balance_provider.dart';
import 'package:beta_caller/services/payment_service.dart';
import 'package:beta_caller/screens/splash_screen.dart';
import 'package:beta_caller/screens/auth/login_screen.dart';
import 'package:beta_caller/screens/home/home_screen.dart';
import 'package:beta_caller/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch any errors during app initialization
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => BalanceProvider()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
      ],
      child: MaterialApp(
        title: 'BetaCaller',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
