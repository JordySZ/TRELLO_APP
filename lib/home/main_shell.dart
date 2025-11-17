import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_app/login/login_page.dart';
import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'home_screen.dart';

import 'starred_boards_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentPageIndex = 0;
  final List<Widget> _pagesContent = [
    const HomeScreenContent(),
    const StarredScreenContent(),
    Container(color: Colors.grey.shade50, child: const Center(child: Text("Pantalla de Recientes (Próximamente)"))), // Página 2
  ];

  // --- INICIO DEL CAMBIO ---

  // 1. Declaramos las variables aquí, fuera del 'build'
  late final User? user;
  late final Stream<QuerySnapshot>? boardsStream;

  @override
  void initState() {
    super.initState();
    // 2. Las inicializamos UNA SOLA VEZ aquí
    user = FirebaseAuth.instance.currentUser;
    boardsStream = user != null
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid) // Podemos usar '!' porque ya comprobamos si es null
            .collection('boards')
            .orderBy('createdAt', descending: true)
            .snapshots()
        : null;
  }
  // --- FIN DEL CAMBIO ---


  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. Ya no necesitamos definir 'user' o 'boardsStream' aquí
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: isDesktop ? null : AppBar(
        title: Text(
          _currentPageIndex == 0 ? 'Mis Tableros' 
          : _currentPageIndex == 1 ? 'Tableros Destacados'
          : 'Recientes',
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      
      drawer: isDesktop ? null : AppDrawer(
        // 4. Usamos las variables de estado
        user: user, 
        onLogout: () => _logout(context), 
        boardsStream: boardsStream,
        currentPageIndex: _currentPageIndex,
        onPageSelected: (index) {
          setState(() => _currentPageIndex = index);
          Navigator.pop(context);
        },
      ),

      body: Row(
        children: [
          if (isDesktop)
            AppDrawer(
              // 4. Usamos las variables de estado
              user: user, 
              onLogout: () => _logout(context), 
              boardsStream: boardsStream,
              currentPageIndex: _currentPageIndex,
              onPageSelected: (index) {
                setState(() => _currentPageIndex = index);
              },
            ),

          Expanded(
            child: _pagesContent[_currentPageIndex],
          ),
        ],
      ),
    );
  }
}