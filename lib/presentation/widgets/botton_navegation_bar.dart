import 'package:flutter/material.dart';

class BottonNavegation extends StatefulWidget {
  const BottonNavegation({super.key});

  @override
  State<BottonNavegation> createState() => _BottonNavegationState();
}

class _BottonNavegationState extends State<BottonNavegation> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color.fromARGB(255, 158, 163, 171),
          unselectedItemColor: Colors.grey,
      
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Hoy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Historial',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),
    );
  }
}