import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/models/app_user_role.dart';
import 'package:tae_app/features/auth/domain/entities/app_user.dart';
import 'package:tae_app/features/auth/domain/entities/registration_request.dart';
import 'package:tae_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:tae_app/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:tae_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:tae_app/features/auth/presentation/controllers/register_account_controller.dart';

void main() {
  test('LoginController trims credentials and toggles loading', () async {
    final signInCompleter = Completer<AppUser>();
    final repository = _FakeAuthRepository(
      signInCallback: () => signInCompleter.future,
    );
    final controller = LoginController(authRepository: repository);
    final loadingStates = <bool>[];
    controller.addListener(() => loadingStates.add(controller.isLoading));

    final signInFuture = controller.signIn(
      email: ' admin@test.com ',
      password: ' secret ',
    );

    expect(controller.isLoading, isTrue);
    expect(repository.signInEmail, 'admin@test.com');
    expect(repository.signInPassword, 'secret');

    signInCompleter.complete(_user);
    final user = await signInFuture;

    expect(user.id, 'user-1');
    expect(controller.isLoading, isFalse);
    expect(loadingStates, [true, false]);

    controller.dispose();
  });

  test(
    'LoginController validates empty credentials before repository call',
    () async {
      final repository = _FakeAuthRepository();
      final controller = LoginController(authRepository: repository);

      await expectLater(
        controller.signIn(email: ' ', password: 'secret'),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            'Por favor, ingresa tu email y contrasena.',
          ),
        ),
      );

      expect(repository.signInCalls, 0);
      expect(controller.isLoading, isFalse);

      controller.dispose();
    },
  );

  test(
    'RegisterAccountController delegates requests and wraps unknown errors',
    () async {
      final repository = _FakeAuthRepository();
      final controller = RegisterAccountController(authRepository: repository);
      final request = _registrationRequest(email: 'new@test.com');

      final user = await controller.register(request);

      expect(repository.registerRequest, same(request));
      expect(user.email, 'new@test.com');
      expect(controller.isLoading, isFalse);

      repository.registerError = StateError('unexpected');
      await expectLater(
        controller.register(request),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            'Ocurrio un error inesperado.',
          ),
        ),
      );

      controller.dispose();
    },
  );

  test(
    'RegisterAccountController rethrows AppException from repository',
    () async {
      final repository = _FakeAuthRepository(
        registerError: const AppException('El correo ya esta registrado.'),
      );
      final controller = RegisterAccountController(authRepository: repository);

      await expectLater(
        controller.register(_registrationRequest()),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            'El correo ya esta registrado.',
          ),
        ),
      );

      expect(controller.isLoading, isFalse);

      controller.dispose();
    },
  );

  test(
    'ForgotPasswordController trims email and validates empty input',
    () async {
      final repository = _FakeAuthRepository();
      final controller = ForgotPasswordController(authRepository: repository);

      await controller.sendResetLink(' reset@test.com ');

      expect(repository.resetEmail, 'reset@test.com');
      expect(controller.isLoading, isFalse);

      await expectLater(
        controller.sendResetLink(' '),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            'Por favor, ingresa tu correo electronico.',
          ),
        ),
      );

      expect(repository.resetCalls, 1);

      controller.dispose();
    },
  );
}

const _user = AppUser(
  id: 'user-1',
  email: 'admin@test.com',
  name: 'Admin',
  role: AppUserRole.admin,
);

RegistrationRequest _registrationRequest({String email = 'user@test.com'}) {
  return RegistrationRequest(
    firstName: 'Ana',
    lastName: 'Lopez',
    middleName: '',
    email: email,
    phone: '555',
    password: 'secret123',
    role: 'alumno',
    profileCategory: 'adulto',
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.signInCallback, this.registerError});

  final Future<AppUser> Function()? signInCallback;
  Object? registerError;

  int signInCalls = 0;
  int resetCalls = 0;
  String? signInEmail;
  String? signInPassword;
  String? resetEmail;
  RegistrationRequest? registerRequest;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    signInEmail = email;
    signInPassword = password;
    if (signInCallback != null) {
      return signInCallback!();
    }
    return _user;
  }

  @override
  Future<AppUser> register(RegistrationRequest request) async {
    registerRequest = request;
    final error = registerError;
    if (error != null) {
      throw error;
    }
    return AppUser(
      id: 'registered-1',
      email: request.email,
      name: request.firstName,
      role: AppUserRole.fromValue(request.role),
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCalls++;
    resetEmail = email;
  }

  @override
  Future<void> signOut() async {}
}
