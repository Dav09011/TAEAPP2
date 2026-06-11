import 'package:tae_app/features/payments/domain/services/checkout_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherCheckoutLauncher implements CheckoutLauncher {
  @override
  Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
