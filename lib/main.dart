import 'package:diuquestionbank/models/course_model.dart';
import 'package:diuquestionbank/models/daily_tip_model.dart';
import 'package:diuquestionbank/models/department_model.dart';
import 'package:diuquestionbank/models/question_model.dart';
import 'package:diuquestionbank/models/slider_model.dart';
import 'package:diuquestionbank/models/task_model.dart';
import 'package:diuquestionbank/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/local/hive_adapters.dart';
import 'firebase_options.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/question_upload_viewmodel.dart';
import 'viewmodels/task_manager_viewmodel.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'viewmodels/notifications_viewmodel.dart';
import 'models/notification_model.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await MobileAds.instance.initialize();
  // Initialize Hive and register adapters
  await Hive.initFlutter();
  registerHiveAdapters();

  // Initialize Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notificationService = NotificationService();
  await notificationService.initialize();

  // Open Hive boxes
  await Hive.openBox<Course>('courses');
  await Hive.openBox<DailyTip>('daily_tips');
  await Hive.openBox<Department>('departments');
  await Hive.openBox<Question>('questions');
  await Hive.openBox<SliderItem>('slider_items');
  await Hive.openBox<Task>('tasks');
  // FIX: Open the 'form_cache' box used by the UploadViewModel.
  await Hive.openBox('form_cache');
  await Hive.openBox<AppNotification>('notifications');

  // Remove the splash screen now that initialization is complete.
  FlutterNativeSplash.remove();


  runApp(
    // Use MultiProvider to make all your ViewModels available
    // to the entire widget tree.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => UploadViewModel()),
        ChangeNotifierProvider(create: (_) => TaskManagerViewModel()),
        // Add this line to provide the missing ViewModel
        ChangeNotifierProvider(create: (_) => UnifiedNotificationViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

