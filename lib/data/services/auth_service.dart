import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class OtpSendResult {
  final bool success;
  final String? message;

  OtpSendResult({
    required this.success,
    this.message,
  });
}

class OtpVerifyResult {
  final bool success;
  final String? message;

  OtpVerifyResult({
    required this.success,
    this.message,
  });
}

class AuthService {
  // =====================================================
  // SEND OTP
  // =====================================================
  static Future<OtpSendResult> sendOtp(String phone) async {
    try {
      final response = await ApiService.post('/auth/send-otp', {
        'phone': phone,
      });

      if (kDebugMode) {
        print('Send OTP status: ${response.statusCode}');
        print('Send OTP response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OtpSendResult(
          success: data['success'] == true,
          message: data['message'] ?? 'OTP sent successfully',
        );
      } else {
        try {
          final data = jsonDecode(response.body);
          return OtpSendResult(
            success: false,
            message: data['message'] ?? 'Failed to send OTP',
          );
        } catch (_) {
          return OtpSendResult(
            success: false,
            message: 'Server error (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Send OTP error: $e');
      }
      return OtpSendResult(
        success: false,
        message: 'Network connection error: $e',
      );
    }
  }

  // =====================================================
  // VERIFY OTP + LOGIN
  // =====================================================
  static Future<OtpVerifyResult> verifyOtp(String phone, String otp) async {
    try {
      final response = await ApiService.post('/auth/verify-otp', {
        'phone': phone,
        'otp': otp,
      });

      if (kDebugMode) {
        print('Verify OTP status: ${response.statusCode}');
        print('Verify OTP response: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }

        if (data['user'] != null) {
          final user = data['user'];
          if (user['id'] != null) await prefs.setString('user_id', user['id'].toString());
          if (user['name'] != null) await prefs.setString('user_name', user['name'].toString());
          if (user['phone'] != null) await prefs.setString('user_phone', user['phone'].toString());
        }

        return OtpVerifyResult(
          success: true,
          message: data['message'] ?? 'Phone number verified successfully!',
        );
      } else {
        return OtpVerifyResult(
          success: false,
          message: data['message'] ?? 'Invalid OTP',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Verify OTP error: $e');
      }
      return OtpVerifyResult(
        success: false,
        message: 'Network connection error: $e',
      );
    }
  }

  // =====================================================
  // USER INFO HELPERS
  // =====================================================
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // =====================================================
  // CHECK LOGIN
  // =====================================================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }
}
