import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/bus_tracker_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BusTrackerApp());
}

/// Paleta de colores de la app
class AppColors {
  AppColors._();

  /// Azul eléctrico — línea de ruta y acento principal
  static const Color routeBlue = Color(0xFF1E88E5);
  static const Color routeBlueBright = Color(0xFF42A5F5);

  /// Naranja UAT — terminal, botones de acción
  static const Color uatOrange = Color(0xFFE65100);
  static const Color uatOrangeLight = Color(0xFFFF8A50);

  /// Fondos oscuros
  static const Color background = Color(0xFF0D1B2A);
  static const Color surface = Color(0xFF1A2942);
  static const Color card = Color(0xFF1E3350);
  static const Color cardElevated = Color(0xFF243D5E);

  /// Texto
  static const Color textPrimary = Color(0xFFE8F1FB);
  static const Color textSecondary = Color(0xFF8DACC8);
  static const Color textMuted = Color(0xFF4A6580);

  /// Estados
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color passed = Color(0xFF37474F);
}

class BusTrackerApp extends StatelessWidget {
  const BusTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusTrackerProvider(),
      child: MaterialApp(
        title: 'Bus UAT Campus Sur',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.routeBlue,
            secondary: AppColors.uatOrange,
            surface: AppColors.surface,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            centerTitle: false,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.routeBlue,
          ),
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
