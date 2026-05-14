import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env loaded first — Supabase needs its URL + key from here.
  await Env.load();

  await Future.wait<void>([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    ),
  ]);

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
