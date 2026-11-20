import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class InternationalAuthResult {
  final bool success;
  final String? message;
  final String phoneNumber;
  final bool needsGoogleConfig;

  const InternationalAuthResult({
    required this.success,
    this.message,
    this.phoneNumber = '',
    this.needsGoogleConfig = false,
  });
}

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
  static Map<String, dynamic> _decodeResponseMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return const <String, dynamic>{};
  }

  static String _extractErrorMessage(
    Map<String, dynamic> data,
    int statusCode,
    String fallback,
  ) {
    final msg = data['message']?.toString().trim();
    if (msg != null && msg.isNotEmpty) return msg;
    final err = data['error']?.toString().trim();
    if (err != null && err.isNotEmpty) return err;
    if (statusCode >= 500) {
      return 'Server error ($statusCode). Please try again.';
    }
    return fallback;
  }

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

      final data = _decodeResponseMap(response.body);
      if (response.statusCode == 200) {
        return OtpSendResult(
          success: data['success'] == true,
          message: data['message']?.toString() ?? 'OTP sent successfully',
        );
      }

      return OtpSendResult(
        success: false,
        message: _extractErrorMessage(
          data,
          response.statusCode,
          'Failed to send OTP',
        ),
      );
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

      final data = _decodeResponseMap(response.body);

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
          if (user['email'] != null && user['email'].toString().isNotEmpty) {
            await prefs.setString('user_email', user['email'].toString());
          }
        }
        await prefs.setString('user_country_code', 'IN');
        await prefs.setString('user_dial_code', '+91');
        await prefs.setString('auth_provider', 'phone_otp');

        return OtpVerifyResult(
          success: true,
          message: data['message']?.toString() ?? 'Phone number verified successfully!',
        );
      } else {
        return OtpVerifyResult(
          success: false,
          message: _extractErrorMessage(
            data,
            response.statusCode,
            'Invalid OTP',
          ),
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

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<String?> getUserDialCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_dial_code');
  }

  static const String _googleClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const String _googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static bool isIndiaCountry({
    required String countryCode,
    String? phoneCode,
  }) {
    final normalizedCode = countryCode.trim().toUpperCase();
    final normalizedDial = (phoneCode ?? '').replaceAll('+', '').trim();
    return normalizedCode == 'IN' || normalizedDial == '91';
  }

  // =====================================================
  // INTERNATIONAL LOGIN (EMAIL OR GOOGLE - NO SMS OTP)
  // =====================================================
  static Future<InternationalAuthResult> loginWithEmail({
    required String email,
    String? name,
    String? phone,
    required String countryCode,
    required String dialCode,
  }) async {
    return _submitInternationalLogin(
      authProvider: 'email',
      email: email.trim(),
      name: name?.trim(),
      phone: phone?.trim(),
      countryCode: countryCode,
      dialCode: dialCode,
    );
  }

  static Future<InternationalAuthResult> signInWithGoogle({
    String? phone,
    required String countryCode,
    required String dialCode,
  }) async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: _googleClientId.isNotEmpty ? _googleClientId : null,
        serverClientId:
            _googleServerClientId.isNotEmpty ? _googleServerClientId : null,
        scopes: const ['email', 'profile'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        return const InternationalAuthResult(
          success: false,
          message: 'Google sign-in was cancelled.',
        );
      }

      final auth = await account.authentication;
      if ((auth.idToken == null || auth.idToken!.isEmpty) &&
          (auth.accessToken == null || auth.accessToken!.isEmpty)) {
        return const InternationalAuthResult(
          success: false,
          message: 'Unable to retrieve Google verification token.',
        );
      }

      return await _submitInternationalLogin(
        authProvider: 'google',
        email: account.email,
        name: account.displayName,
        phone: phone?.trim(),
        countryCode: countryCode,
        dialCode: dialCode,
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
    } on Object catch (e) {
      debugPrint('Google Sign-In error: $e');
      final lower = e.toString().toLowerCase();
      final bool isConfigError = e is AssertionError ||
          lower.contains('clientid') ||
          lower.contains('client_id') ||
          lower.contains('gidclientid') ||
          lower.contains('developer_error') ||
          lower.contains('apiexception: 10') ||
          lower.contains('unconfigured');

      if (isConfigError) {
        return const InternationalAuthResult(
          success: false,
          needsGoogleConfig: true,
          message:
              'Google Sign-In is not configured yet for this build. Please sign in with your Email ID or configure GOOGLE_CLIENT_ID.',
        );
      }

      return const InternationalAuthResult(
        success: false,
        message: 'Google sign-in failed. Please try again or use Email ID.',
      );
    }
  }

  static Future<InternationalAuthResult> _submitInternationalLogin({
    required String authProvider,
    required String email,
    String? name,
    String? phone,
    required String countryCode,
    required String dialCode,
    String? idToken,
    String? accessToken,
  }) async {
    try {
      final response = await ApiService.post('/auth/international-login', {
        'authProvider': authProvider,
        'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'countryCode': countryCode,
        'dialCode': dialCode,
        if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
        if (accessToken != null && accessToken.isNotEmpty)
          'accessToken': accessToken,
      });

      final data = _decodeResponseMap(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true &&
          data['token'] != null) {
        final String savedPhone = await _persistInternationalSession(
          data: data,
          fallbackEmail: email,
          fallbackName: name,
          fallbackPhone: phone,
          countryCode: countryCode,
          dialCode: dialCode,
          authProvider: authProvider,
        );
        return InternationalAuthResult(
          success: true,
          message: data['message']?.toString(),
          phoneNumber: savedPhone,
        );
      }

      return InternationalAuthResult(
        success: false,
        message: _extractErrorMessage(
          data,
          response.statusCode,
          'Login failed. Please try again.',
        ),
      );
    } catch (e) {
      debugPrint('International login error: $e');
      return const InternationalAuthResult(
        success: false,
        message: 'Connection error. Please try again.',
      );
    }
  }

  static Future<String> _persistInternationalSession({
    required Map<String, dynamic> data,
    required String fallbackEmail,
    String? fallbackName,
    String? fallbackPhone,
    required String countryCode,
    required String dialCode,
    required String authProvider,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token'].toString());

    final user = (data['user'] is Map<String, dynamic>)
        ? data['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    if (user['id'] != null) {
      await prefs.setString('user_id', user['id'].toString());
    }

    final resolvedName =
        (user['name']?.toString().trim().isNotEmpty == true)
            ? user['name'].toString().trim()
            : (fallbackName?.trim() ?? '');
    if (resolvedName.isNotEmpty) {
      await prefs.setString('user_name', resolvedName);
    }

    final resolvedEmail =
        (user['email']?.toString().trim().isNotEmpty == true)
            ? user['email'].toString().trim()
            : fallbackEmail;
    await prefs.setString('user_email', resolvedEmail);

    final rawPhone = (user['phone']?.toString().trim().isNotEmpty == true)
        ? user['phone'].toString().trim()
        : (fallbackPhone?.trim() ?? '');
    final resolvedPhone = rawPhone.startsWith('intl_') ? '' : rawPhone;

    if (resolvedPhone.isNotEmpty) {
      await prefs.setString('user_phone', resolvedPhone);
    } else {
      await prefs.remove('user_phone');
    }
    await prefs.remove('phone_number');

    await prefs.setString('user_country_code', countryCode);
    await prefs.setString('user_dial_code', dialCode);
    await prefs.setString('auth_provider', authProvider);

    return resolvedPhone;
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString('auth_provider');
    if (provider == 'google') {
      try {
        await GoogleSignIn(
          clientId: _googleClientId.isNotEmpty ? _googleClientId : null,
          serverClientId:
              _googleServerClientId.isNotEmpty ? _googleServerClientId : null,
        ).signOut();
      } catch (_) {}
    }
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
