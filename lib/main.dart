import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/shop.dart';
import 'models/item.dart';
import 'models/app_settings.dart';

import 'providers/shop_provider.dart';

import 'services/notification_service.dart';

import 'core/theme/app_theme.dart';

import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // HIVE INITIALIZATION
  // ============================================================

  await Hive.initFlutter();

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ShopAdapter());
  }

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ItemAdapter());
  }

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }

  // ============================================================
  // OPEN HIVE BOXES
  // ============================================================

  await Hive.openBox<Shop>('shops');
  await Hive.openBox<Item>('items');
  await Hive.openBox<AppSettings>('settings');

  // ============================================================
  // NOTIFICATION INITIALIZATION
  // ============================================================

  await NotificationService.instance.init();

  // Request notification permission
  await NotificationService.instance.requestPermissions();

  // ============================================================
  // CHECK WELCOME SCREEN
  // ============================================================

  final prefs = await SharedPreferences.getInstance();

  final bool welcomeScreenShown =
      prefs.getBool('welcome_screen_shown') ?? false;

  // ============================================================
  // START APP
  // ============================================================

  runApp(
    UdhaaroApp(
      showWelcomeScreen: !welcomeScreenShown,
    ),
  );
}

// ================================================================
// UDHAARO APP
// ================================================================

class UdhaaroApp extends StatelessWidget {
  final bool showWelcomeScreen;

  const UdhaaroApp({
    super.key,
    required this.showWelcomeScreen,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShopProvider(),

      child: MaterialApp(
        title: 'Udhaaro',

        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,

        home: showWelcomeScreen
            ? const WelcomeScreen()
            : const HomeScreen(),
      ),
    );
  }
}