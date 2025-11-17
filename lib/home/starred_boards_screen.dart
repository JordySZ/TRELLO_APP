import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart'; // Importa HomeScreen para Board, BoardsSection, BoardCard
// Ya no importamos 'app_drawer.dart' ni 'login_page.dart' aquí

// --- CAMBIO: Renombrado a StarredScreenContent ---
class StarredScreenContent extends StatelessWidget {
  const StarredScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // Stream para destacados
    final Stream<QuerySnapshot>? starredBoardsStream = user != null
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('boards')
            .where('isStarred', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots()
        : null;

    // Stream para todos los tableros (para el conteo)
    final Stream<QuerySnapshot>? allBoardsStream = user != null
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('boards')
            .snapshots()
        : null;

    // --- CAMBIO: No hay Scaffold, ni Row, ni AppDrawer. Solo el contenido.
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 32),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableros Destacados',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Acceso rápido a tus tableros más importantes',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tarjetas de Resumen
            StreamBuilder<QuerySnapshot>(
              stream: starredBoardsStream,
              builder: (context, starredSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: allBoardsStream,
                  builder: (context, allBoardsSnapshot) {
                    // ... (Lógica de snapshots sin cambios)
                    if (starredSnapshot.connectionState == ConnectionState.waiting ||
                        allBoardsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (starredSnapshot.hasError || allBoardsSnapshot.hasError) {
                      return Text('Error: ${starredSnapshot.error ?? allBoardsSnapshot.error}');
                    }
                    final int numStarredBoards = starredSnapshot.data?.docs.length ?? 0;
                    final int totalBoards = allBoardsSnapshot.data?.docs.length ?? 0;
                    final double percentageStarred = totalBoards > 0 ? (numStarredBoards / totalBoards) * 100 : 0;

                    return Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.star,
                            iconColor: Colors.amber,
                            value: numStarredBoards,
                            label: 'Tableros destacados',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.dashboard,
                            iconColor: Colors.indigo,
                            value: totalBoards,
                            label: 'Total de tableros',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.pie_chart,
                            iconColor: Colors.orange,
                            value: percentageStarred.round(),
                            label: 'Destacados',
                            isPercentage: true,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 48),

            // Sección "Mis favoritos"
            const Text(
              'Mis favoritos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Haz clic en la estrella para quitar de destacados',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Grid de Tableros (reutilizando BoardsSection)
            StreamBuilder<QuerySnapshot>(
              stream: starredBoardsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error al cargar favoritos: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Text(
                        'Aún no tienes tableros destacados. Marca algunos desde Inicio.',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final starredBoards = snapshot.data!.docs
                    .map((doc) => Board.fromFirestore(doc))
                    .toList();
                
                return BoardsSection(
                  title: '',
                  boards: starredBoards,
                  showStar: true,
                );
              },
            ),
            const SizedBox(height: 48),

            // Tarjeta de Consejo
            _TipCard(
              icon: Icons.lightbulb_outline,
              iconColor: Colors.orange,
              title: 'Consejo',
              description:
                  'Marca tus tableros más importantes como destacados para acceder rápidamente a ellos. Puedes agregar o quitar la estrella haciendo clic en el icono en cualquier tablero.',
            ),
          ],
        ),
      ),
    );
  }
}


// --- Componentes Privados de esta pantalla (Sin cambios) ---

class _SummaryCard extends StatelessWidget {
  // ... (Sin cambios)
  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;
  final bool isPercentage;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.isPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(height: 12),
            Text(
              isPercentage ? '$value%' : '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  // ... (Sin cambios)
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _TipCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}