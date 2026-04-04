import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'SETTING/app_language.dart';
import 'auth/login_screen.dart';
import 'TrangChu.dart';
import 'filebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppLanguage(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appLang = context.watch<AppLanguage>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: appLang.locale,

      // 🔥 AUTO LOGIN
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          // ⏳ Đang load Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // ✅ Đã đăng nhập → vào Trang Chủ
          if (snapshot.hasData) {
            return const TrangChu();
          }

          // ❌ Chưa đăng nhập → vào Login
          return const LoginScreen();
        },
      ),
    );
  }
}