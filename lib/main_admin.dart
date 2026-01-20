import 'package:cheat_days/core/theme/app_theme.dart';
import 'package:cheat_days/features/admin/presentation/admin_login_screen.dart';
import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// Entry point for Web Admin
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check for Web (using Debug for now, ReCaptchaEnterprise in prod)
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider(
      'recaptcha-site-key',
    ), // Placeholder or Debug
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(const ProviderScope(child: MessieAdminApp()));
}

class MessieAdminApp extends StatelessWidget {
  const MessieAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messie Admin',
      theme: AppTheme.theme,
      home: const AdminLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
