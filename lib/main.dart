import 'package:flutter/material.dart';

import 'screen/dashboard_screen.dart';
import 'services/hive_service.dart';

final Future<void> _appInitialization = HiveService.initialize();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinanceTrackerApp());
}

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF090A14);
    const surface = Color(0xFF111426);
    const surfaceAlt = Color(0xFF171B31);
    const primary = Color(0xFF14F1FF);
    const secondary = Color(0xFFFF2BD6);
    const accent = Color(0xFF9D7CFF);

    final colorScheme = const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: Color(0xFFFF5B7F),
      onPrimary: Color(0xFF051018),
      onSecondary: Colors.white,
      onSurface: Color(0xFFF4F7FF),
    );

    return MaterialApp(
      title: 'Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        dividerColor: Colors.white10,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: surfaceAlt,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFF4F7FF),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFF4F7FF),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: surface,
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: surface,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(
              color: Color(0x22FFFFFF),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          labelStyle: const TextStyle(color: Color(0xFFAAB2D5)),
          hintStyle: const TextStyle(color: Color(0x668EA0D1)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: primary,
              width: 1.4,
            ),
          ),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: const Color(0xFFF4F7FF),
              displayColor: const Color(0xFFF4F7FF),
            ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: const Color(0xFF051018),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accent,
          ),
        ),
      ),
      home: FutureBuilder<void>(
        future: _appInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Initialization failed:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          return const DashboardScreen();
        },
      ),
    );
  }
}
