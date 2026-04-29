import 'package:flutter/material.dart';
import 'package:tae_app/app/router/app_routes.dart';
import 'package:tae_app/features/admin/presentation/pages/main_branches_page.dart';
import 'package:tae_app/features/admin/presentation/pages/wallet_fees_page.dart';
import 'package:tae_app/features/admin/presentation/pages/wallet_page.dart';
import 'package:tae_app/features/admin/presentation/pages/wallet_student_status_page.dart';
import 'package:tae_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:tae_app/features/auth/presentation/pages/login_page.dart';
import 'package:tae_app/features/auth/presentation/pages/register_admin_page.dart';
import 'package:tae_app/features/auth/presentation/pages/register_teacher_student_page.dart';
import 'package:tae_app/features/auth/presentation/pages/type_register_page.dart';
import 'package:tae_app/features/licensing/presentation/pages/license_selection_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _build(const LoginPage(), settings);
      case AppRoutes.forgotPassword:
        return _build(const ForgotPasswordPage(), settings);
      case AppRoutes.typeRegister:
        return _build(const TypeRegister(), settings);
      case AppRoutes.registerAdmin:
        return _build(const RegisterAdmin(), settings);
      case AppRoutes.registerUser:
        return _build(const RegisterTeacherStudent(), settings);
      case AppRoutes.licenseSelection:
        return _build(const LicenciaScreen(), settings);
      case AppRoutes.mainAdmin:
        return _build(const MainBranches(), settings);
      case AppRoutes.wallet:
        return _build(const WalletScreen(), settings);
      case AppRoutes.walletFees:
        return _build(const WalletFeesPage(), settings);
      case AppRoutes.walletStudentStatus:
        return _build(const WalletStudentStatusPage(), settings);
      default:
        return _build(const LoginPage(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _build(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
