import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Storage is Firebase Cloud Storage (migrated off Supabase once the
  // project moved to Blaze). Uploads use the signed-in user's Firebase
  // token automatically — no separate anonymous sign-in needed.

  // FCM push (NAD-39). Fully defensive — never blocks startup.
  await NotificationService.init();

  runApp(const StrayfriendsApp());
}

class StrayfriendsApp extends StatefulWidget {
  const StrayfriendsApp({super.key});

  @override
  State<StrayfriendsApp> createState() => _StrayfriendsAppState();
}

class _StrayfriendsAppState extends State<StrayfriendsApp> {
  late final _router = buildAppRouter();

  @override
  void initState() {
    super.initState();
    // Notification tap → deep link into the app (e.g. /activity/:id).
    NotificationService.onNavigate = (route) => _router.go(route);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Strayfriends',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
