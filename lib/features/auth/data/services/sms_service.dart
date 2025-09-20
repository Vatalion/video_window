import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../../core/error/exceptions.dart';

abstract class SmsService {
  Future<bool> sendVerificationCode(String phoneNumber, String code);
  Future<bool> sendTwoFactorCode(String phoneNumber, String code);
  Future<bool> sendAccountRecoveryCode(String phoneNumber, String code);
}

class TwilioSmsService implements SmsService {
  final Dio dio;
  final Logger logger;
  final String accountSid;
  final String authToken;
  final String fromNumber;

  TwilioSmsService({
    required this.dio,
    required this.logger,
    required this.accountSid,
    required this.authToken,
    required this.fromNumber,
  });

  @override
  Future<bool> sendVerificationCode(String phoneNumber, String code) async {
    try {
      final response = await dio.post(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
        options: Options(
          headers: {
            'Authorization':
                'Basic ${base64.encode(utf8.encode('$accountSid:$authToken'))}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'To': phoneNumber,
          'From': fromNumber,
          'Body':
              'Your verification code is: $code. This code expires in 10 minutes.',
        },
      );

      if (response.statusCode == 201) {
        logger.i('SMS verification code sent successfully to $phoneNumber');
        return true;
      } else {
        logger.e(
          'Failed to send SMS verification code: ${response.statusCode}',
        );
        throw ServerException('Failed to send SMS verification code');
      }
    } on DioException catch (e) {
      logger.e('SMS service error: ${e.message}');
      throw ServerException('SMS service unavailable: ${e.message}');
    } catch (e) {
      logger.e('Unexpected error sending SMS: ${e.toString()}');
      throw ServerException('Failed to send SMS verification code');
    }
  }

  @override
  Future<bool> sendTwoFactorCode(String phoneNumber, String code) async {
    try {
      final response = await dio.post(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
        options: Options(
          headers: {
            'Authorization':
                'Basic ${base64.encode(utf8.encode('$accountSid:$authToken'))}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'To': phoneNumber,
          'From': fromNumber,
          'Body':
              'Your 2FA code is: $code. Do not share this code with anyone.',
        },
      );

      if (response.statusCode == 201) {
        logger.i('2FA SMS code sent successfully to $phoneNumber');
        return true;
      } else {
        logger.e('Failed to send 2FA SMS code: ${response.statusCode}');
        throw ServerException('Failed to send 2FA SMS code');
      }
    } on DioException catch (e) {
      logger.e('SMS service error: ${e.message}');
      throw ServerException('SMS service unavailable: ${e.message}');
    } catch (e) {
      logger.e('Unexpected error sending 2FA SMS: ${e.toString()}');
      throw ServerException('Failed to send 2FA SMS code');
    }
  }

  @override
  Future<bool> sendAccountRecoveryCode(String phoneNumber, String code) async {
    try {
      final response = await dio.post(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
        options: Options(
          headers: {
            'Authorization':
                'Basic ${base64.encode(utf8.encode('$accountSid:$authToken'))}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'To': phoneNumber,
          'From': fromNumber,
          'Body':
              'Your account recovery code is: $code. Use this code to recover your account.',
        },
      );

      if (response.statusCode == 201) {
        logger.i('Account recovery SMS code sent successfully to $phoneNumber');
        return true;
      } else {
        logger.e(
          'Failed to send account recovery SMS code: ${response.statusCode}',
        );
        throw ServerException('Failed to send account recovery SMS code');
      }
    } on DioException catch (e) {
      logger.e('SMS service error: ${e.message}');
      throw ServerException('SMS service unavailable: ${e.message}');
    } catch (e) {
      logger.e(
        'Unexpected error sending account recovery SMS: ${e.toString()}',
      );
      throw ServerException('Failed to send account recovery SMS code');
    }
  }
}

class MockSmsService implements SmsService {
  final Logger logger;

  MockSmsService(this.logger);

  @override
  Future<bool> sendVerificationCode(String phoneNumber, String code) async {
    logger.i('[MOCK] SMS verification code sent to $phoneNumber: $code');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<bool> sendTwoFactorCode(String phoneNumber, String code) async {
    logger.i('[MOCK] 2FA SMS code sent to $phoneNumber: $code');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<bool> sendAccountRecoveryCode(String phoneNumber, String code) async {
    logger.i('[MOCK] Account recovery SMS code sent to $phoneNumber: $code');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
