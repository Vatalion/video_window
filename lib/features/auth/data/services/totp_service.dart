import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:otp/otp.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/exceptions.dart';

abstract class TotpService {
  String generateSecret();
  String generateQrCodeUrl({
    required String secret,
    required String userId,
    required String appName,
  });
  bool verifyCode(String secret, String code, {int? timeWindow});
  String generateBackupCode();
  List<String> generateBackupCodes({int count = 10});
}

class TotpServiceImpl implements TotpService {
  final Logger logger;
  final Uuid uuid;

  TotpServiceImpl({required this.logger, required this.uuid});

  @override
  String generateSecret() {
    try {
      final random = List<int>.generate(
        20,
        (i) => DateTime.now().millisecondsSinceEpoch ~/ (i + 1),
      );
      final secret = base32.encode(random);
      logger.i('Generated new TOTP secret');
      return secret;
    } catch (e) {
      logger.e('Failed to generate TOTP secret: ${e.toString()}');
      throw CacheException('Failed to generate TOTP secret');
    }
  }

  @override
  String generateQrCodeUrl({
    required String secret,
    required String userId,
    required String appName,
  }) {
    try {
      final encodedSecret = secret.replaceAll('=', '');
      final uri = Uri(
        scheme: 'otpauth',
        host: 'totp',
        path: '$appName:$userId',
        queryParameters: {
          'secret': encodedSecret,
          'issuer': appName,
          'algorithm': 'SHA1',
          'digits': '6',
          'period': '30',
        },
      );

      logger.i('Generated QR code URL for user: $userId');
      return uri.toString();
    } catch (e) {
      logger.e('Failed to generate QR code URL: ${e.toString()}');
      throw CacheException('Failed to generate QR code URL');
    }
  }

  @override
  bool verifyCode(String secret, String code, {int? timeWindow}) {
    try {
      if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
        logger.w('Invalid TOTP code format: $code');
        return false;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeStep = 30;
      final timeCounter = currentTime ~/ timeStep;

      if (timeWindow != null) {
        for (int i = -timeWindow; i <= timeWindow; i++) {
          final counter = timeCounter + i;
          final expectedCode = OTP.generateTOTPCode(
            secret: secret,
            interval: timeStep,
            algorithm: Algorithm.SHA1,
            length: 6,
            time: counter * timeStep,
          );

          if (expectedCode == code) {
            logger.i('TOTP code verified successfully for time window: $i');
            return true;
          }
        }
      } else {
        final expectedCode = OTP.generateTOTPCode(
          secret: secret,
          interval: timeStep,
          algorithm: Algorithm.SHA1,
          length: 6,
          time: currentTime,
        );

        if (expectedCode == code) {
          logger.i('TOTP code verified successfully');
          return true;
        }
      }

      logger.w('Invalid TOTP code: $code');
      return false;
    } catch (e) {
      logger.e('Failed to verify TOTP code: ${e.toString()}');
      return false;
    }
  }

  @override
  String generateBackupCode() {
    try {
      final code = uuid.v4().substring(0, 8).toUpperCase();
      logger.i('Generated backup code');
      return code;
    } catch (e) {
      logger.e('Failed to generate backup code: ${e.toString()}');
      throw CacheException('Failed to generate backup code');
    }
  }

  @override
  List<String> generateBackupCodes({int count = 10}) {
    try {
      final codes = <String>[];
      for (int i = 0; i < count; i++) {
        codes.add(generateBackupCode());
      }
      logger.i('Generated $count backup codes');
      return codes;
    } catch (e) {
      logger.e('Failed to generate backup codes: ${e.toString()}');
      throw CacheException('Failed to generate backup codes');
    }
  }
}
