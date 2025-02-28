// auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> signUp(String email, String password) async {
    try {
      await supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> verifyOtp(String email, String token) async {
    try {
      await supabase.auth.verifyOTP(token: token, type: OtpType.email, email: email);
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}