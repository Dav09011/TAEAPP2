import 'package:flutter/material.dart';
import 'package:tae_app/app/router/app_routes.dart';
import 'package:tae_app/features/admin/presentation/pages/main_branches_page.dart';
import 'package:tae_app/features/admin/presentation/pages/wallet_fees_page.dart';
import 'package:tae_app/features/admin/presentation/pages/wallet_page.dart';
import 'package:tae_app/features/admin/presentation/pages/wallet_performance_detail_page.dart';
import 'package:tae_app/features/admin/presentation/pages/wallet_student_status_page.dart';
import 'package:tae_app/modules/admin/pages/cash_payment_requests.dart';
import 'package:tae_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:tae_app/features/auth/presentation/pages/login_page.dart';
import 'package:tae_app/features/auth/presentation/pages/register_admin_page.dart';
import 'package:tae_app/features/auth/presentation/pages/register_teacher_student_page.dart';
import 'package:tae_app/features/auth/presentation/pages/type_register_page.dart';
import 'package:tae_app/features/licensing/presentation/pages/license_selection_page.dart';

class AppRouter {
  static final Map<String, WidgetBuilder> routes = {
    AppRoutes.login: (context) => const LoginPage(),
    AppRoutes.forgotPassword: (context) => const ForgotPasswordPage(),
    AppRoutes.typeRegister: (context) => const TypeRegister(),
    AppRoutes.registerAdmin: (context) => const RegisterAdmin(),
    AppRoutes.registerUser: (context) => const RegisterTeacherStudent(),
    AppRoutes.licenseSelection: (context) => const LicenciaScreen(),
    AppRoutes.mainAdmin: (context) => const MainBranches(),
    AppRoutes.wallet: (context) => const WalletScreen(),
    AppRoutes.walletPerformance:
        (context) => const WalletPerformanceDetailPage(),
    AppRoutes.walletFees: (context) => const WalletFeesPage(),
    AppRoutes.walletStudentStatus: (context) => const WalletStudentStatusPage(),
    AppRoutes.cashPayments: (context) => const CashPaymentRequestsScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    // Ruta por defecto si no se encuentra la ruta
    return MaterialPageRoute(
      builder: (_) => const LoginPage(),
      settings: settings,
    );
  }
}
