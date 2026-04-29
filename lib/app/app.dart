import 'package:flutter/material.dart';
import 'package:tae_app/app/router/app_router.dart';
import 'package:tae_app/app/router/app_routes.dart';

class TaeApp extends StatelessWidget {
  const TaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAE App',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: AppRouter.routes, // Usar el mapa de rutas
      onGenerateRoute: AppRouter.onGenerateRoute,
    ); // Manejar rutas dinámicas);
  }
}
