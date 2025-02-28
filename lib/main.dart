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
    url: 'https://ptfaqewjxwzbzvyskjfx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0ZmFxZXdqeHd6Ynp2eXNramZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA1NDk1ODgsImV4cCI6MjA1NjEyNTU4OH0.ioY0tD0O7JsTMOsD3pUext8eiTZFC1mTXZzwJp_IPHo',
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
