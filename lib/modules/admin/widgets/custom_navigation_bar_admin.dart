import 'package:flutter/material.dart';

// A esta clase no es recomendable meterle como tal las pantallas por
// la cual la barra de navegacion tendra que redireccionar, esto es por el simple hecho 
// de que esta debe de ser para un uso generico y no específico
class CustomNavigationBarAdmin extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavigationBarAdmin({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFF9F4FB),
      elevation: 10,
      selectedItemColor: const Color(0xFF5B3FA8),
      unselectedItemColor: const Color(0xFF7A727C),
      selectedFontSize: 13,
      unselectedFontSize: 12,
      iconSize: 28,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Inicio'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'Calendario',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Cartera',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}


