import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/water_provider.dart';
import 'firebase_options.dart';

import 'providers/calorie_journal.dart';
import 'providers/medicine_catalog.dart';

import 'screens/splash_screen.dart';
import 'services/local_store.dart';
import 'services/notification_service.dart';
import 'services/voice_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must complete before any provider reads LocalStore (Home, Meds, Food tabs).
  await LocalStore.init();


  await AndroidAlarmManager.initialize();
  try {

    await Firebase.initializeApp(
      options:
      DefaultFirebaseOptions
          .currentPlatform,
    );

  } catch (e) {

    debugPrint(
      'Firebase init: $e',
    );
  }
  FirebaseFirestore.instance.settings =
  const Settings(
    persistenceEnabled: true,
  );
  try {
    await initNotifications();
  } catch (e) {
    debugPrint('Notifications init: $e');
  }


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MedicineCatalog(),
        ),
        ChangeNotifierProvider(
          create: (_) => VoiceService(),
        ),
        ChangeNotifierProvider(
          create: (_) => CalorieJournal(),
        ),
        ChangeNotifierProvider(
          create: (_) => WaterProvider(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'MediVoice AI',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFAED9D5),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}





