import 'package:fpdart/fpdart.dart';
import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/auth/domain/entities/auth_user.dart';
import 'package:kudlit_ph/features/auth/domain/entities/sign_up_status.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  AuthUser? get currentUser;

  Future<Either<Failure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> signInWithGoogle();

  Future<Either<Failure, Unit>> sendPhoneOtp({required String phoneNumber});

  Future<Either<Failure, Unit>> verifyPhoneOtp({
    required String phoneNumber,
    required String token,
  });

  Future<Either<Failure, SignUpStatus>> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, Unit>> resetPassword({required String email});

  /// Permanently deletes the current user's account and all associated data,
  /// then signs out locally. Required by App Store 5.1.1(v) and Play policy.
  Future<Either<Failure, Unit>> deleteAccount();
}
