import 'package:flutter/widgets.dart';
import 'package:tae_app/app/app.dart';
import 'package:tae_app/core/config/firebase_bootstrap.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  runApp(const TaeApp());
}
