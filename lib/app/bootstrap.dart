import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mealmitra/core/config/app_config.dart';
import 'package:mealmitra/firebase_options.dart';
import 'package:mealmitra/core/services/notification_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.useFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized: ✅');
      
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await NotificationService().initialize();
      debugPrint('NotificationService initialized: ✅');
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }
}
