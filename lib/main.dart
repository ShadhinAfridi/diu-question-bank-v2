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
// Caching services
import 'services/cache_manager.dart';
import 'services/connectivity_service.dart';
import 'repositories/question_cache_repository.dart';
import 'viewmodels/cached_question_viewmodel.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await MobileAds.instance.initialize();

  // Initialize Hive and register adapters
  await Hive.initFlutter();
  registerHiveAdapters();

  // Initialize Firebase
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
  await Hive.openBox('form_cache');
  await Hive.openBox<AppNotification>('notifications');
  await Hive.openBox('sync_times'); // For cache management

  // Remove the splash screen
  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        // Core services (lazy initialization)
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => ConnectivityService(),
          lazy: false, // Initialize immediately
        ),
        ChangeNotifierProvider<CacheManager>(
          create: (_) => CacheManager(),
          lazy: false, // Initialize immediately
        ),

        // Existing ViewModels
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => UploadViewModel()),
        ChangeNotifierProvider(create: (_) => TaskManagerViewModel()),
        ChangeNotifierProvider(create: (_) => UnifiedNotificationViewModel()),

        // Caching repositories and ViewModels
        ProxyProvider<HomeViewModel, QuestionCacheRepository>(
          create: (context) => QuestionCacheRepository(
            userDepartmentId: context.read<HomeViewModel>().userDepartmentId,
          ),
          update: (context, homeViewModel, repository) =>
          repository ?? QuestionCacheRepository(
            userDepartmentId: homeViewModel.userDepartmentId,
          ),
        ),
        ChangeNotifierProxyProvider<QuestionCacheRepository, CachedQuestionViewModel>(
          create: (context) => CachedQuestionViewModel(
            repository: context.read<QuestionCacheRepository>(),
          ),
          update: (context, repository, previous) =>
          previous ?? CachedQuestionViewModel(repository: repository!),
        ),
      ],
      child: const MyApp(),
    ),
  );
}