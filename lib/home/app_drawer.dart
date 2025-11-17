import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_app/Tableros/board_screen.dart';
import 'package:flutter/material.dart';


import 'create_board_dialog.dart';
import 'starred_boards_screen.dart';
import 'home_screen.dart' show Board; // <--- AÑADIDO para el color

// --- Widget del Menú Lateral (AppDrawer) ---
class AppDrawer extends StatelessWidget {
  final User? user;
  final VoidCallback onLogout;
  final Stream<QuerySnapshot>? boardsStream;
  final int currentPageIndex;
  final ValueChanged<int> onPageSelected;

  const AppDrawer({
    super.key,
    required this.user,
    required this.onLogout,
    required this.boardsStream,
    required this.currentPageIndex,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    final Widget sidebarContent = Container(
      width: 280,
      color: Colors.grey.shade900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('TaskFlow', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          
          // Perfil
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
            child: Container(
              padding: const EdgeInsets.only(bottom: 24.0),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade700.withOpacity(0.5)))),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.indigo.shade700,
                    child: Text(user?.email?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'Usuario', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                        Text(user?.email ?? 'usuario@example.com', style: TextStyle(color: Colors.grey.shade400, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Menú Principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DrawerItem(
                    title: 'Inicio',
                    icon: Icons.home,
                    isSelected: currentPageIndex == 0,
                    onTap: () => onPageSelected(0),
                  ),
                  DrawerItem(
                    title: 'Destacados',
                    icon: Icons.star_border,
                    isSelected: currentPageIndex == 1,
                    onTap: () => onPageSelected(1),
                  ),
                  DrawerItem(
                    title: 'Recientes',
                    icon: Icons.access_time,
                    isSelected: currentPageIndex == 2,
                    onTap: () => onPageSelected(2),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tableros
                  const DrawerSectionTitle(title: 'TABLEROS', showAdd: true),
                  StreamBuilder<QuerySnapshot>(
                    stream: boardsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                          child: Text("Crea tu primer tablero", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                        );
                      }
                      
                      // --- CAMBIO: Mapeamos a BoardListItemData ---
                      final boards = snapshot.data!.docs.map((doc) => BoardListItemData.fromFirestore(doc)).toList();
                      
                      return Column(
                        children: boards.map((board) {
                          // --- CAMBIO: Usamos el nuevo BoardListItem ---
                          return BoardListItem(
                            board: board,
                            // Lógica para marcar como seleccionado si esta pantalla es
                            // un BoardScreen y el ID del tablero coincide
                            // (Esto es avanzado, lo dejamos simple por ahora)
                            isSelected: false, 
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Espacios de Trabajo
                  const DrawerSectionTitle(title: 'ESPACIOS DE TRABAJO'),
                  DrawerItem(
                    title: 'Equipo de Desarrollo',
                    icon: Icons.rocket_launch,
                    onTap: () {},
                    isWorkspace: true,
                  ),
                ],
              ),
            ),
          ),
          
          // Pie de Página
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade700.withOpacity(0.5)))),
            child: Column(
              children: [
                DrawerItem(title: 'Configuración', icon: Icons.settings, onTap: () {}),
                DrawerItem(title: 'Cerrar Sesión', icon: Icons.logout, onTap: onLogout),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isDesktop) {
      return Drawer(child: sidebarContent);
    }
    return sidebarContent;
  }
}

// --- Componentes del Drawer ---

class DrawerItem extends StatelessWidget {
  // ... (Sin cambios)
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isWorkspace;

  const DrawerItem({
    super.key,
    required this.title,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
    this.isWorkspace = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade300, size: isWorkspace ? 20 : 24),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade300,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: isWorkspace ? 14 : 16,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      tileColor: isSelected ? Colors.indigo.shade800.withOpacity(0.5) : Colors.transparent,
      hoverColor: Colors.grey.shade800.withOpacity(0.8),
      onTap: onTap,
    );
  }
}

// --- CAMBIO: Modelo de datos solo para el item de la lista ---
class BoardListItemData {
  final String id;
  final String title;
  final Color color;

  BoardListItemData({required this.id, required this.title, required this.color});

  factory BoardListItemData.fromFirestore(DocumentSnapshot doc) {
     Map data = doc.data() as Map<String, dynamic>;

     Color parseColor(String hex) {
      try {
        final buffer = StringBuffer();
        if (hex.length == 6 || hex.length == 7) buffer.write('ff');
        buffer.write(hex.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return const Color(0xFF808080);
      }
    }

    return BoardListItemData(
      id: doc.id, // <--- AÑADIDO: Necesitamos el ID
      title: data['title'] ?? 'Sin Título',
      color: parseColor(data['colorHex'] ?? '808080'),
    );
  }
}


// --- CAMBIO: BoardListItem ahora recibe el modelo y maneja el onTap ---
class BoardListItem extends StatelessWidget {
  final BoardListItemData board;
  final bool isSelected;

  const BoardListItem({
    super.key,
    required this.board,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: board.color, borderRadius: BorderRadius.circular(4)),
      ),
      title: Text(
        board.title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade300,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      tileColor: isSelected ? Colors.indigo.shade800.withOpacity(0.5) : Colors.transparent,
      hoverColor: Colors.grey.shade800.withOpacity(0.8),
      onTap: () {
        // --- AÑADIDO: Navegación a la pantalla del tablero ---
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context); // Cierra el drawer si está en móvil
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BoardScreen(
              boardId: board.id,
              boardTitle: board.title,
              boardColor: board.color,
            ),
          ),
        );
      },
    );
  }
}


class DrawerSectionTitle extends StatelessWidget {
  // ... (Sin cambios)
  final String title;
  final bool showAdd;

  const DrawerSectionTitle({super.key, required this.title, this.showAdd = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          if (showAdd)
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                if (Scaffold.of(context).isDrawerOpen) {
                  Navigator.pop(context);
                }
                showDialog(
                  context: context,
                  builder: (BuildContext context) => const CreateBoardDialog(),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Icon(Icons.add, color: Colors.grey.shade500, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}