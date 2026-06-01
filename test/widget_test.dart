import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tae_app/features/auth/domain/entities/app_user.dart';
import 'package:tae_app/features/auth/domain/entities/registration_request.dart';
import 'package:tae_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:tae_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:tae_app/login_page.dart';

void main() {
  testWidgets('login form renders without Firebase', (tester) async {
    final loginController = LoginController(
      authRepository: _FakeAuthRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(home: LoginPage(loginController: loginController)),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Iniciar Sesion'), findsOneWidget);
    expect(find.text('No tienes una cuenta?'), findsOneWidget);
    expect(find.text('Registrate'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);

    loginController.dispose();
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AppUser> signIn({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> register(RegistrationRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }
}
