// main.dart
import 'package:cloudgalary/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'signup_screen.dart';
import 'otp_screen.dart';
import 'home_screen.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: '',
    anonKey:
        '',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/otp': (context) => OtpScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
