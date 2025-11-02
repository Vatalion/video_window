# Authentication Flow Implementation Examples

**Effective Date:** 2025-10-09
**Target Framework:** Flutter 3.19.6, Serverpod 2.9.x

## Overview

This document provides complete implementation examples for the authentication system, including email/SMS sign-in, social login, biometric authentication, and session management.

## Core Authentication Architecture

### System Components

```
lib/
├── features/
│   └── auth/
│       ├── data/
│       │   ├── models/
│       │   │   ├── user_model.dart
│       │   │   ├── auth_request.dart
│       │   │   └── session_model.dart
│       │   ├── datasources/
│       │   │   ├── auth_remote_data_source.dart
│       │   │   ├── auth_local_data_source.dart
│       │   │   └── biometric_data_source.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── user_entity.dart
│       │   │   └── auth_result.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── usecases/
│       │       ├── sign_in_usecase.dart
│       │       ├── sign_up_usecase.dart
│       │       └── sign_out_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── auth_bloc.dart
│           │   ├── auth_event.dart
│           │   └── auth_state.dart
│           ├── pages/
│           │   ├── login_page.dart
│           │   ├── register_page.dart
│           │   └── forgot_password_page.dart
│           └── widgets/
│               ├── email_form.dart
│               ├── social_login_buttons.dart
│               └── biometric_prompt.dart
```

## 1. Data Models

### User Model

```dart
// lib/features/auth/data/models/user_model.dart

import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final bool isMaker;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> providers;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.isEmailVerified,
    required this.isMaker,
    required this.createdAt,
    required this.updatedAt,
    required this.providers,
    this.metadata,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isEmailVerified: isEmailVerified,
      isMaker: isMaker,
      createdAt: createdAt,
      updatedAt: updatedAt,
      providers: providers,
      metadata: metadata,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      isEmailVerified: entity.isEmailVerified,
      isMaker: entity.isMaker,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      providers: entity.providers,
      metadata: entity.metadata,
    );
  }
}
```

### Authentication Request Model

```dart
// lib/features/auth/data/models/auth_request.dart

import 'package:json_annotation/json_annotation.dart';

part 'auth_request.g.dart';

@JsonSerializable()
class EmailSignInRequest {
  final String email;
  final String password;

  EmailSignInRequest({
    required this.email,
    required this.password,
  });

  factory EmailSignInRequest.fromJson(Map<String, dynamic> json) =>
      _$EmailSignInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EmailSignInRequestToJson(this);
}

@JsonSerializable()
class EmailSignUpRequest {
  final String email;
  final String password;
  final String displayName;
  final bool? isMaker;

  EmailSignUpRequest({
    required this.email,
    required this.password,
    required this.displayName,
    this.isMaker,
  });

  factory EmailSignUpRequest.fromJson(Map<String, dynamic> json) =>
      _$EmailSignUpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EmailSignUpRequestToJson(this);
}

@JsonSerializable()
class SocialSignInRequest {
  final String provider;
  final String accessToken;
  final String? idToken;

  SocialSignInRequest({
    required this.provider,
    required this.accessToken,
    this.idToken,
  });

  factory SocialSignInRequest.fromJson(Map<String, dynamic> json) =>
      _$SocialSignInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SocialSignInRequestToJson(this);
}
```

## 2. Remote Data Source

### Authentication Remote Data Source

```dart
// lib/features/auth/data/datasources/auth_remote_data_source.dart

import 'package:serverpod_client/serverpod_client.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../models/auth_request.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail(EmailSignInRequest request);
  Future<UserModel> signUpWithEmail(EmailSignUpRequest request);
  Future<UserModel> signInWithSocial(SocialSignInRequest request);
  Future<void> signOut();
  Future<UserModel> refreshSession();
  Future<void> sendEmailVerification(String email);
  Future<void> sendPasswordResetEmail(String email);
  Future<bool> verifyEmail(String code);
  Future<UserModel> updateProfile(Map<String, dynamic> data);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> signInWithEmail(EmailSignInRequest request) async {
    try {
      final response = await client.auth.signInWithEmail(request);
      return UserModel.fromJson(response);
    } on ServerpodClientException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel> signUpWithEmail(EmailSignUpRequest request) async {
    try {
      final response = await client.auth.signUpWithEmail(request);
      return UserModel.fromJson(response);
    } on ServerpodClientException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel> signInWithSocial(SocialSignInRequest request) async {
    try {
      final response = await client.auth.signInWithSocial(request);
      return UserModel.fromJson(response);
    } on ServerpodClientException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on ServerpodClientException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel> refreshSession() async {
    try {
      final response = await client.auth.refreshSession();
      return UserModel.fromJson(response);
    } on ServerpodClientException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> sendEmailVerification(String email) async {
    try {
      await client.auth.sendEmailVerification(email);
    } on ServerpodClientException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await client.auth.sendPasswordResetEmail(email);
    } on ServerpodClientException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<bool> verifyEmail(String code) async {
    try {
      final result = await client.auth.verifyEmail(code);
      return result;
    } on ServerpodClientException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await client.auth.updateProfile(data);
      return UserModel.fromJson(response);
    } on ServerpodClientException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Exception _handleAuthException(ServerpodClientException e) {
    switch (e.statusCode) {
      case 400:
        return AuthException('Invalid request parameters');
      case 401:
        return AuthException('Invalid credentials');
      case 409:
        return AuthException('Email already exists');
      case 422:
        return AuthException('Validation failed');
      default:
        return AuthException('Authentication failed: ${e.message}');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
```

## 3. Local Data Source

### Authentication Local Data Source

```dart
// lib/features/auth/data/datasources/auth_local_data_source.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> cacheSession(SessionModel session);
  Future<SessionModel?> getCachedSession();
  Future<void> clearCache();
  Future<void> saveAuthToken(String token);
  Future<String?> getAuthToken();
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _cachedUserKey = 'CACHED_USER';
  static const String _cachedSessionKey = 'CACHED_SESSION';
  static const String _authTokenKey = 'AUTH_TOKEN';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheUser(UserModel user) async {
    await sharedPreferences.setString(
      _cachedUserKey,
      user.toJson(),
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString(_cachedUserKey);
    if (jsonString != null) {
      return UserModel.fromJson(jsonString);
    }
    return null;
  }

  @override
  Future<void> cacheSession(SessionModel session) async {
    await sharedPreferences.setString(
      _cachedSessionKey,
      session.toJson(),
    );
  }

  @override
  Future<SessionModel?> getCachedSession() async {
    final jsonString = sharedPreferences.getString(_cachedSessionKey);
    if (jsonString != null) {
      return SessionModel.fromJson(jsonString);
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_cachedUserKey);
    await sharedPreferences.remove(_cachedSessionKey);
    await sharedPreferences.remove(_authTokenKey);
  }

  @override
  Future<void> saveAuthToken(String token) async {
    await sharedPreferences.setString(_authTokenKey, token);
  }

  @override
  Future<String?> getAuthToken() async {
    return sharedPreferences.getString(_authTokenKey);
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    final user = await getCachedUser();
    return token != null && user != null;
  }
}
```

## 4. Repository Implementation

### Authentication Repository

```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/biometric_data_source.dart';
import '../models/user_model.dart';
import '../models/auth_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final BiometricDataSource biometricDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.biometricDataSource,
  });

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    final request = EmailSignInRequest(
      email: email,
      password: password,
    );

    final user = await remoteDataSource.signInWithEmail(request);

    await localDataSource.cacheUser(user);

    return user.toEntity();
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    bool? isMaker,
  }) async {
    final request = EmailSignUpRequest(
      email: email,
      password: password,
      displayName: displayName,
      isMaker: isMaker,
    );

    final user = await remoteDataSource.signUpWithEmail(request);

    await localDataSource.cacheUser(user);

    return user.toEntity();
  }

  @override
  Future<UserEntity> signInWithSocial({
    required String provider,
    required String accessToken,
    String? idToken,
  }) async {
    final request = SocialSignInRequest(
      provider: provider,
      accessToken: accessToken,
      idToken: idToken,
    );

    final user = await remoteDataSource.signInWithSocial(request);

    await localDataSource.cacheUser(user);

    return user.toEntity();
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();
    await localDataSource.clearCache();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final cachedUser = await localDataSource.getCachedUser();
    return cachedUser?.toEntity();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }

  @override
  Future<UserEntity> refreshSession() async {
    final user = await remoteDataSource.refreshSession();
    await localDataSource.cacheUser(user);
    return user.toEntity();
  }

  @override
  Future<void> sendEmailVerification(String email) async {
    await remoteDataSource.sendEmailVerification(email);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await remoteDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<bool> verifyEmail(String code) async {
    return await remoteDataSource.verifyEmail(code);
  }

  @override
  Future<UserEntity> updateProfile(Map<String, dynamic> data) async {
    final user = await remoteDataSource.updateProfile(data);
    await localDataSource.cacheUser(user);
    return user.toEntity();
  }

  @override
  Future<bool> isBiometricAvailable() async {
    return await biometricDataSource.isBiometricAvailable();
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    return await biometricDataSource.authenticate();
  }

  @override
  Future<void> enableBiometricAuth() async {
    await biometricDataSource.enableBiometricAuth();
  }

  @override
  Future<void> disableBiometricAuth() async {
    await biometricDataSource.disableBiometricAuth();
  }
}
```

## 5. Use Cases

### Sign In Use Case

```dart
// lib/features/auth/domain/usecases/sign_in_usecase.dart

import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  final AuthRepository repository;

  SignInWithEmailUseCase({required this.repository});

  Future<UserEntity> call({
    required String email,
    required String password,
  }) async {
    return await repository.signInWithEmail(email, password);
  }
}

class SignUpWithEmailUseCase {
  final AuthRepository repository;

  SignUpWithEmailUseCase({required this.repository});

  Future<UserEntity> call({
    required String email,
    required String password,
    required String displayName,
    bool? isMaker,
  }) async {
    return await repository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
      isMaker: isMaker,
    );
  }
}

class SignInWithSocialUseCase {
  final AuthRepository repository;

  SignInWithSocialUseCase({required this.repository});

  Future<UserEntity> call({
    required String provider,
    required String accessToken,
    String? idToken,
  }) async {
    return await repository.signInWithSocial(
      provider: provider,
      accessToken: accessToken,
      idToken: idToken,
    );
  }
}

class SignOutUseCase {
  final AuthRepository repository;

  SignOutUseCase({required this.repository});

  Future<void> call() async {
    await repository.signOut();
  }
}
```

## 6. BLoC Implementation

### Authentication BLoC

```dart
// lib/features/auth/presentation/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmailUseCase signInWithEmail;
  final SignUpWithEmailUseCase signUpWithEmail;
  final SignInWithSocialUseCase signInWithSocial;
  final SignOutUseCase signOut;

  AuthBloc({
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.signInWithSocial,
    required this.signOut,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInEmailRequested>(_onSignInEmailRequested);
    on<SignUpEmailRequested>(_onSignUpEmailRequested);
    on<SignInSocialRequested>(_onSignInSocialRequested);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await signInWithEmail.repository.getCurrentUser();

      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInEmailRequested(
    SignInEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await signInWithEmail(
        email: event.email,
        password: event.password,
      );

      emit(Authenticated(user: user));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> _onSignUpEmailRequested(
    SignUpEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await signUpWithEmail(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        isMaker: event.isMaker,
      );

      emit(Authenticated(user: user));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> _onSignInSocialRequested(
    SignInSocialRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await signInWithSocial(
        provider: event.provider,
        accessToken: event.accessToken,
        idToken: event.idToken,
      );

      emit(Authenticated(user: user));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(const AuthError(message: 'Failed to sign out'));
    }
  }
}
```

### Authentication Events

```dart
// lib/features/auth/presentation/bloc/auth_event.dart

part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class SignInEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class SignUpEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  final bool? isMaker;

  const SignUpEmailRequested({
    required this.email,
    required this.password,
    required this.displayName,
    this.isMaker,
  });

  @override
  List<Object> get props => [email, password, displayName, isMaker];
}

class SignInSocialRequested extends AuthEvent {
  final String provider;
  final String accessToken;
  final String? idToken;

  const SignInSocialRequested({
    required this.provider,
    required this.accessToken,
    this.idToken,
  });

  @override
  List<Object> get props => [provider, accessToken, idToken];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
```

### Authentication States

```dart
// lib/features/auth/presentation/bloc/auth_state.dart

part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}
```

## 7. UI Implementation

### Login Page

```dart
// lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/email_form.dart';
import '../widgets/social_login_buttons.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(context).pushReplacementNamed('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue to Craft Marketplace',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const EmailForm(),
                const SizedBox(height: 24),
                const SocialLoginButtons(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/register');
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Email Form Widget

```dart
// lib/features/auth/presentation/widgets/email_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class EmailForm extends StatefulWidget {
  const EmailForm({Key? key}) : super(key: key);

  @override
  State<EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignInPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            SignInEmailRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state is AuthLoading ? null : _onSignInPressed,
                  child: state is AuthLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/forgot-password');
                },
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Social Login Buttons

```dart
// lib/features/auth/presentation/widgets/social_login_buttons.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../bloc/auth_bloc.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({Key? key}) : super(key: key);

  Future<void> _onGoogleSignIn(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();

      if (account != null) {
        final authentication = await account.authentication;

        context.read<AuthBloc>().add(
              SignInSocialRequested(
                provider: 'google',
                accessToken: authentication.accessToken!,
                idToken: authentication.idToken,
              ),
            );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign in with Google'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onAppleSignIn(BuildContext context) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken != null) {
        context.read<AuthBloc>().add(
              SignInSocialRequested(
                provider: 'apple',
                accessToken: credential.authorizationCode,
                idToken: credential.identityToken,
              ),
            );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign in with Apple'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _onGoogleSignIn(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/google.png',
                      height: 24,
                      width: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text('Google'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _onAppleSignIn(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, size: 24),
                    const SizedBox(width: 12),
                    const Text('Apple'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

## 8. Dependency Injection

### Auth Module Setup

```dart
// lib/features/auth/auth_module.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serverpod_client/serverpod_client.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/biometric_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/sign_in_usecase.dart';
import 'domain/usecases/sign_up_usecase.dart';
import 'domain/usecases/sign_out_usecase.dart';
import 'presentation/bloc/auth_bloc.dart';

class AuthModule {
  static Future<void> setup() async {
    // Initialize dependencies
    final sharedPreferences = await SharedPreferences.getInstance();
    final client = Client('http://localhost:8080/')
      ..authenticationKey = ''; // Will be set after login
    final biometricDataSource = BiometricDataSourceImpl();

    // Data sources
    final remoteDataSource = AuthRemoteDataSourceImpl(client: client);
    final localDataSource = AuthLocalDataSourceImpl(
      sharedPreferences: sharedPreferences,
    );

    // Repository
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      biometricDataSource: biometricDataSource,
    );

    // Use cases
    final signInWithEmail = SignInWithEmailUseCase(repository: authRepository);
    final signUpWithEmail = SignUpWithEmailUseCase(repository: authRepository);
    final signInWithSocial = SignInWithSocialUseCase(repository: authRepository);
    final signOut = SignOutUseCase(repository: authRepository);

    // Register BLoC
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(
        signInWithEmail: signInWithEmail,
        signUpWithEmail: signUpWithEmail,
        signInWithSocial: signInWithSocial,
        signOut: signOut,
      ),
    );
  }
}
```

## 9. Testing

### Authentication BLoC Test

```dart
// test/features/auth/presentation/bloc/auth_bloc_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/domain/entities/user_entity.dart';
import 'package:video_window/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_bloc.dart';

class MockSignInUseCase extends Mock implements SignInWithEmailUseCase {}
class MockSignUpUseCase extends Mock implements SignUpWithEmailUseCase {}
class MockSignInSocialUseCase extends Mock implements SignInWithSocialUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockSignInUseCase mockSignInUseCase;
  late MockSignUpUseCase mockSignUpUseCase;
  late MockSignInSocialUseCase mockSignInSocialUseCase;
  late MockSignOutUseCase mockSignOutUseCase;

  setUp(() {
    mockSignInUseCase = MockSignInUseCase();
    mockSignUpUseCase = MockSignUpUseCase();
    mockSignInSocialUseCase = MockSignInSocialUseCase();
    mockSignOutUseCase = MockSignOutUseCase();

    authBloc = AuthBloc(
      signInWithEmail: mockSignInUseCase,
      signUpWithEmail: mockSignUpUseCase,
      signInWithSocial: mockSignInSocialUseCase,
      signOut: mockSignOutUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  const testUser = UserEntity(
    id: '1',
    email: 'test@example.com',
    displayName: 'Test User',
    isEmailVerified: true,
    isMaker: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    providers: ['email'],
  );

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when signIn is successful',
      build: () {
        when(() => mockSignInUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => testUser);

        return authBloc;
      },
      act: (bloc) => bloc.add(
        const SignInEmailRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [
        AuthLoading(),
        Authenticated(user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when signIn fails',
      build: () {
        when(() => mockSignInUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(Exception('Invalid credentials'));

        return authBloc;
      },
      act: (bloc) => bloc.add(
        const SignInEmailRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [
        AuthLoading(),
        const AuthError(message: 'An unexpected error occurred'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when signOut is successful',
      build: () {
        when(() => mockSignOutUseCase()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const SignOutRequested()),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );
  });
}
```

## 10. Serverpod Endpoint Implementation

### Authentication Endpoints

```dart
// server/lib/endpoints/auth_endpoint.dart

import 'package:serverpod/serverpod.dart';

class AuthEndpoint extends Endpoint {
  Future<User> signInWithEmail(
    Session session,
    EmailSignInRequest request,
  ) async {
    // Validate request
    if (request.email.isEmpty || request.password.isEmpty) {
      throw InvalidRequestException('Email and password are required');
    }

    // Check if user exists
    final user = await User.find(
      session,
      where: (t) => t.email.equals(request.email),
    );

    if (user == null) {
      throw UnauthorizedException('Invalid email or password');
    }

    // Verify password (using bcrypt or similar)
    final isValidPassword = await _verifyPassword(
      request.password,
      user.passwordHash,
    );

    if (!isValidPassword) {
      throw UnauthorizedException('Invalid email or password');
    }

    // Create session
    await _createUserSession(session, user);

    return user;
  }

  Future<User> signUpWithEmail(
    Session session,
    EmailSignUpRequest request,
  ) async {
    // Validate request
    if (request.email.isEmpty ||
        request.password.isEmpty ||
        request.displayName.isEmpty) {
      throw InvalidRequestException('All fields are required');
    }

    // Check if user already exists
    final existingUser = await User.find(
      session,
      where: (t) => t.email.equals(request.email),
    );

    if (existingUser != null) {
      throw ConflictException('Email already exists');
    }

    // Hash password
    final passwordHash = await _hashPassword(request.password);

    // Create user
    final user = User(
      email: request.email,
      passwordHash: passwordHash,
      displayName: request.displayName,
      isMaker: request.isMaker ?? false,
      isEmailVerified: false,
      providers: ['email'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await User.insert(session, user);

    // Create session
    await _createUserSession(session, user);

    return user;
  }

  Future<void> signOut(Session session) async {
    // Invalidate current session
    await session.authenticatedUserId = null;
    await session.save(session);
  }

  Future<User> refreshSession(Session session) async {
    final userId = session.authenticatedUserId;
    if (userId == null) {
      throw UnauthorizedException('No active session');
    }

    final user = await User.findById(session, userId);
    if (user == null) {
      throw UnauthorizedException('User not found');
    }

    return user;
  }

  Future<void> sendEmailVerification(
    Session session,
    String email,
  ) async {
    // Generate verification code
    final verificationCode = _generateVerificationCode();

    // Store verification code with expiration
    final verification = EmailVerification(
      email: email,
      code: verificationCode,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now(),
    );

    await EmailVerification.insert(session, verification);

    // Send verification email
    await _sendVerificationEmail(email, verificationCode);
  }

  Future<bool> verifyEmail(Session session, String code) async {
    final verification = await EmailVerification.find(
      session,
      where: (t) => t.code.equals(code) & t.expiresAt.greaterThan(DateTime.now()),
    );

    if (verification == null) {
      return false;
    }

    // Mark user as verified
    final user = await User.find(
      session,
      where: (t) => t.email.equals(verification.email),
    );

    if (user != null) {
      user.isEmailVerified = true;
      user.updatedAt = DateTime.now();
      await User.update(session, user);
    }

    // Delete verification code
    await EmailVerification.delete(session, verification);

    return true;
  }

  // Helper methods
  Future<String> _hashPassword(String password) async {
    // Use a proper password hashing library like bcrypt
    return password; // Placeholder - implement proper hashing
  }

  Future<bool> _verifyPassword(
    String password,
    String passwordHash,
  ) async {
    // Verify password using the same hashing method
    return password == passwordHash; // Placeholder - implement proper verification
  }

  String _generateVerificationCode() {
    // Generate a random 6-digit code
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<void> _createUserSession(Session session, User user) async {
    session.authenticatedUserId = user.id;
    await session.save(session);
  }

  Future<void> _sendVerificationEmail(String email, String code) async {
    // Implement email sending logic
    // This could use services like SendGrid, AWS SES, etc.
  }
}
```

---

**Last Updated:** 2025-10-09
**Related Examples:** [BLoC Implementation Guide](../bloc-implementation-guide.md) | [Serverpod Integration](../serverpod-integration-guide.md) | [Security Patterns](../pattern-library.md#security-patterns)