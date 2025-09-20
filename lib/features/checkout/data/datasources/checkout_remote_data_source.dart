import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import '../../domain/models/checkout_session_model.dart';
import '../../domain/models/checkout_validation_model.dart';
import '../../domain/models/order_summary_model.dart';
import '../../domain/models/payment_model.dart';
import '../../domain/models/address_model.dart';
import '../../domain/models/checkout_security_model.dart';

abstract class CheckoutRemoteDataSource {
  // Session Management
  Future<Either<Failure, Map<String, dynamic>>> createSession({
    required String userId,
    bool isGuest = false,
  });

  Future<Either<Failure, Map<String, dynamic>>> getSession(String sessionId);

  Future<Either<Failure, bool>> updateSession({
    required String sessionId,
    required Map<String, dynamic> updates,
  });

  Future<Either<Failure, bool>> saveSessionProgress({
    required String sessionId,
    required Map<String, dynamic> stepData,
  });

  Future<Either<Failure, Map<String, dynamic>>> resumeSession(String sessionId);

  Future<Either<Failure, bool>> abandonSession(String sessionId);

  // Validation
  Future<Either<Failure, Map<String, dynamic>>> validateCheckoutStep({
    required String sessionId,
    required String stepType,
    required Map<String, dynamic> stepData,
    required Map<String, dynamic> securityContext,
  });

  // Order Calculation
  Future<Either<Failure, Map<String, dynamic>>> calculateOrderSummary({
    required Map<String, dynamic> request,
    required String sessionId,
  });

  // Payment Processing
  Future<Either<Failure, Map<String, dynamic>>> processPayment({
    required String sessionId,
    required String paymentMethodId,
    required double amount,
    required Map<String, dynamic> securityContext,
  });

  Future<Either<Failure, bool>> validatePaymentMethod({
    required String paymentMethodId,
    required Map<String, dynamic> securityContext,
  });

  // Address Management
  Future<Either<Failure, Map<String, dynamic>>> saveAddress({
    required Map<String, dynamic> address,
    required Map<String, dynamic> securityContext,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getUserAddresses(String userId);

  // Security
  Future<Either<Failure, Map<String, dynamic>>> validateSecurityContext({
    required String sessionId,
    required Map<String, dynamic> context,
  });

  Future<Either<Failure, bool>> recordSecurityEvent({
    required Map<String, dynamic> event,
  });

  // Order Completion
  Future<Either<Failure, String>> completeCheckout({
    required String sessionId,
    required String paymentMethodId,
    required Map<String, dynamic> securityContext,
  });

  // Guest Checkout
  Future<Either<Failure, String>> createGuestAccount({
    required String email,
    required String firstName,
    required String lastName,
    required String sessionId,
  });

  // Analytics
  Future<Either<Failure, bool>> trackAbandonment({
    required String sessionId,
    required String reason,
  });

  Future<Either<Failure, bool>> trackStepCompletion({
    required String sessionId,
    required String stepType,
    required int timeSpentSeconds,
  });
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  final Dio dio;

  CheckoutRemoteDataSourceImpl({required this.dio});

  @override
  Future<Either<Failure, Map<String, dynamic>>> createSession({
    required String userId,
    bool isGuest = false,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/sessions',
        data: {
          'userId': userId,
          'isGuest': isGuest,
        },
      );

      if (response.statusCode == 201) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: 'Failed to create checkout session',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while creating session',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while creating session',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSession(String sessionId) async {
    try {
      final response = await dio.get('/checkout/sessions/$sessionId');

      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: 'Failed to retrieve checkout session',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(NotFoundFailure(
          message: 'Checkout session not found',
        ));
      }
      return Left(ServerFailure(
        message: 'Network error while retrieving session',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while retrieving session',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> updateSession({
    required String sessionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await dio.put(
        '/checkout/sessions/$sessionId',
        data: updates,
      );

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Failed to update checkout session',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while updating session',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while updating session',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> saveSessionProgress({
    required String sessionId,
    required Map<String, dynamic> stepData,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/sessions/$sessionId/progress',
        data: {'stepData': stepData},
      );

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Failed to save session progress',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while saving progress',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while saving progress',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> resumeSession(String sessionId) async {
    try {
      final response = await dio.post('/checkout/sessions/$sessionId/resume');

      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: 'Failed to resume checkout session',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while resuming session',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while resuming session',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> abandonSession(String sessionId) async {
    try {
      final response = await dio.post('/checkout/sessions/$sessionId/abandon');

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Failed to abandon checkout session',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while abandoning session',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while abandoning session',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> validateCheckoutStep({
    required String sessionId,
    required String stepType,
    required Map<String, dynamic> stepData,
    required Map<String, dynamic> securityContext,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/sessions/$sessionId/validate',
        data: {
          'stepType': stepType,
          'stepData': stepData,
          'securityContext': securityContext,
        },
      );

      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: 'Failed to validate checkout step',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while validating step',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while validating step',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> calculateOrderSummary({
    required Map<String, dynamic> request,
    required String sessionId,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/sessions/$sessionId/calculate',
        data: request,
      );

      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: 'Failed to calculate order summary',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while calculating order',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while calculating order',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> processPayment({
    required String sessionId,
    required String paymentMethodId,
    required double amount,
    required Map<String, dynamic> securityContext,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/sessions/$sessionId/payment',
        data: {
          'paymentMethodId': paymentMethodId,
          'amount': amount,
          'securityContext': securityContext,
        },
      );

      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: 'Failed to process payment',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while processing payment',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while processing payment',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> validatePaymentMethod({
    required String paymentMethodId,
    required Map<String, dynamic> securityContext,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/payment-methods/$paymentMethodId/validate',
        data: {'securityContext': securityContext},
      );

      if (response.statusCode == 200) {
        return Right(response.data['isValid'] ?? false);
      } else {
        return Left(ServerFailure(
          message: 'Failed to validate payment method',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while validating payment method',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while validating payment method',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> saveAddress({
    required Map<String, dynamic> address,
    required Map<String, dynamic> securityContext,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/addresses',
        data: {
          'address': address,
          'securityContext': securityContext,
        },
      );

      if (response.statusCode == 201) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: 'Failed to save address',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while saving address',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while saving address',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserAddresses(String userId) async {
    try {
      final response = await dio.get('/checkout/users/$userId/addresses');

      if (response.statusCode == 200) {
        return Right(List<Map<String, dynamic>>.from(response.data['addresses'] ?? []));
      } else {
        return Left(ServerFailure(
          message: 'Failed to retrieve user addresses',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while retrieving addresses',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while retrieving addresses',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> validateSecurityContext({
    required String sessionId,
    required Map<String, dynamic> context,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/sessions/$sessionId/security/validate',
        data: {'context': context},
      );

      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
        return Left(ServerFailure(
          message: 'Failed to validate security context',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while validating security context',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while validating security context',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> recordSecurityEvent({
    required Map<String, dynamic> event,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/security/events',
        data: event,
      );

      if (response.statusCode == 201) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Failed to record security event',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while recording security event',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while recording security event',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, String>> completeCheckout({
    required String sessionId,
    required String paymentMethodId,
    required Map<String, dynamic> securityContext,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/sessions/$sessionId/complete',
        data: {
          'paymentMethodId': paymentMethodId,
          'securityContext': securityContext,
        },
      );

      if (response.statusCode == 200) {
        return Right(response.data['orderId'] as String);
      } else {
        return Left(ServerFailure(
          message: 'Failed to complete checkout',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while completing checkout',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while completing checkout',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, String>> createGuestAccount({
    required String email,
    required String firstName,
    required String lastName,
    required String sessionId,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/guest-accounts',
        data: {
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'sessionId': sessionId,
        },
      );

      if (response.statusCode == 201) {
        return Right(response.data['userId'] as String);
      } else {
        return Left(ServerFailure(
          message: 'Failed to create guest account',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while creating guest account',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while creating guest account',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> trackAbandonment({
    required String sessionId,
    required String reason,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/sessions/$sessionId/abandonment',
        data: {'reason': reason},
      );

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Failed to track abandonment',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while tracking abandonment',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while tracking abandonment',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> trackStepCompletion({
    required String sessionId,
    required String stepType,
    required int timeSpentSeconds,
  }) async {
    try {
      final response = await dio.post(
        '/checkout/sessions/$sessionId/step-completion',
        data: {
          'stepType': stepType,
          'timeSpentSeconds': timeSpentSeconds,
        },
      );

      if (response.statusCode == 200) {
        return Right(true);
      } else {
        return Left(ServerFailure(
          message: 'Failed to track step completion',
          details: response.data,
        ));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: 'Network error while tracking step completion',
        details: e.response?.data,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error while tracking step completion',
        details: e.toString(),
      ));
    }
  }
}