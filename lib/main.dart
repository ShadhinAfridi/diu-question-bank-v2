// main.dart - Enhanced version
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

// Import your models and adapters for Hive
import 'data/local/hive_adapters.dart';
import 'models/point_transaction_model.dart';
import 'models/question_model.dart';
import 'models/slider_model.dart';
import 'models/subscription_model.dart';
import 'models/task_model.dart';
import 'models/user_model.dart';
import 'models/notification_model.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize core components
  await _initializeApp();

  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initializeApp() async {
  try {
    debugPrint('App: Initializing Firebase...');
    // Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('App: Initializing Mobile Ads...');
    // Mobile Ads
    await MobileAds.instance.initialize();

    debugPrint('App: Initializing Hive...');
    // Initialize Hive
    await _initializeHive();

    debugPrint('App: All initializations complete');
  } catch (e, st) {
    debugPrint('App: Error during initialization: $e\n$st');
    rethrow;
  }
}

Future<void> _initializeHive() async {
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Register all adapters
    registerHiveAdapters();

    // Safe box opening with retry logic
    Future<Box<T>> openBoxSafely<T>(String name) async {
      try {
        final box = await Hive.openBox<T>(name);
        debugPrint('Hive: Successfully opened box $name with ${box.keys.length} keys');
        return box;
      } catch (e, st) {
        debugPrint('Hive: ERROR opening box $name: $e');
        debugPrint('Stack trace: $st');

        // Try to delete and recreate the box if it's corrupted
        try {
          await Hive.deleteBoxFromDisk(name);
          debugPrint('Hive: Deleted corrupted box $name');

          final newBox = await Hive.openBox<T>(name);
          debugPrint('Hive: Recreated box $name successfully');
          return newBox;
        } catch (e2) {
          debugPrint('Hive: Failed to recreate box $name: $e2');
          rethrow;
        }
      }
    }

    // Open all boxes
    await Future.wait([
      openBoxSafely<Question>('questions_v3'),
      openBoxSafely<PointTransaction>('point_transactions_v3'),
      openBoxSafely<UserModel>('users_v3'),
      openBoxSafely<SliderItem>('sliders_v3'),
      openBoxSafely<Subscription>('subscriptions_v3'),
      openBoxSafely<Task>('tasks_v3'),
      openBoxSafely('form_cache_v3'),
      openBoxSafely('app_meta_v3'),
      openBoxSafely<NotificationSettings>('notification_settings_v3'),
      openBoxSafely<AppNotification>('notification_history_v3'),
    ]);

    // Verify all boxes are working
    final metaBox = Hive.box('app_meta_v3');
    debugPrint('Hive: Meta box contains: ${metaBox.keys}');

    final userBox = Hive.box<UserModel>('users_v3');
    debugPrint('Hive: User box contains ${userBox.keys.length} users');

    debugPrint('App: Hive initialized successfully');
  } catch (e, st) {
    debugPrint('App: CRITICAL ERROR during Hive initialization: $e\n$st');
    rethrow;
  }
}