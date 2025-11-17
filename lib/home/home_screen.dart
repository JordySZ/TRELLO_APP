import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_app/Tableros/board_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_board_dialog.dart';
import 'starred_boards_screen.dart';
import 'app_drawer.dart';


// --- MODELOS DE DATOS (Se quedan aquí) ---

class Board {
  final String id;
  final String title;
  final Color color;
  final IconData icon;
  final bool isStarred;

  Board({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
    required this.isStarred,
  });

  factory Board.fromFirestore(DocumentSnapshot doc) {
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

    IconData parseIcon(int codePoint) {
      try {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      } catch (e) {
        return Icons.article_outlined;
      }
    }

    return Board(
      id: doc.id,
      title: data['title'] ?? 'Sin Título',
      color: parseColor(data['colorHex'] ?? '808080'),
      icon: parseIcon(data['iconCodePoint'] ?? 0xe04f),
      isStarred: data['isStarred'] ?? false,
    );
  }
}

class Workspace {
  final String name;
  final int members;
  final int boards;

  const Workspace(this.name, this.members, this.boards);
}

const List<Workspace> workspaces = [
  Workspace('Equipo de Desarrollo', 4, 4),
];


// --- HomeScreenContent (Sin cambios) ---
class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final Stream<QuerySnapshot>? boardsStream = user != null
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('boards')
            .orderBy('createdAt', descending: true)
            .snapshots()
        : null;

    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: boardsStream,
          builder: (context, snapshot) {
            
            List<Board> starredBoards = [];
            List<Board> recentBoards = [];

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final allBoards = snapshot.data!.docs
                  .map((doc) => Board.fromFirestore(doc))
                  .toList();
              
              starredBoards = allBoards.where((b) => b.isStarred).toList();
              recentBoards = allBoards;
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(50.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error al cargar tableros: ${snapshot.error}'),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mis Tableros', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Text('Gestiona tus proyectos de forma colaborativa y eficiente', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 32),
                BoardsSection(title: 'Tableros destacados', boards: starredBoards, showStar: true),
                const SizedBox(height: 32),
                BoardsSection(title: 'Tableros recientes', boards: recentBoards, showStar: false),
                const SizedBox(height: 32),
                WorkspacesSection(workspaces: workspaces),
              ],
            );
          },
        ),
      ),
    );
  }
}


// --- Componentes del Contenido (Widgets Públicos) ---

class BoardsSection extends StatelessWidget {
  // ... (Sin cambios)
  final String title;
  final List<Board> boards;
  final bool showStar;
  const BoardsSection({super.key, required this.title, required this.boards, required this.showStar});
  @override
  Widget build(BuildContext context) {
    if (showStar && boards.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              if (showStar) const Icon(Icons.star, color: Colors.amber, size: 24),
              if (showStar) const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = (constraints.maxWidth / 250).floor();
            final safeCrossAxisCount = crossAxisCount < 1 ? 1 : (crossAxisCount > 4 ? 4 : crossAxisCount);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: safeCrossAxisCount,
                crossAxisSpacing: 24.0,
                mainAxisSpacing: 24.0,
                childAspectRatio: 1.5,
              ),
              itemCount: boards.length + (showStar ? 0 : 1),
              itemBuilder: (context, index) {
                if (!showStar && index == boards.length) {
                  return NewBoardCard();
                }
                final board = boards[index];
                return BoardCard(board: board);
              },
            );
          },
        ),
      ],
    );
  }
}

// ===================================================================
// --- INICIO DE CAMBIOS ---
// (Widget BoardCard actualizado con lógica de eliminación)
// ===================================================================

class BoardCard extends StatelessWidget {
  final Board board;
  const BoardCard({super.key, required this.board});

  /// Alterna el estado de "Destacado"
  Future<void> _toggleStarStatus(BuildContext context, Board board) {
    // ... (Lógica de la estrella sin cambios)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado.')),
      );
      return Future.value();
    }
    final newStatus = !board.isStarred;
    final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('boards')
          .doc(board.id);
    
    return docRef.update({'isStarred': newStatus})
      .then((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus
                    ? '"${board.title}" añadido a destacados'
                    : '"${board.title}" quitado de destacados',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      })
      .catchError((e) {
         if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar: $e')),
          );
        }
      });
  }

  // --- AÑADIDO: Lógica para eliminar el tablero y sus subcolecciones ---
  Future<void> _deleteBoard(BuildContext context, Board board) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Referencia al tablero
    final boardRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('boards')
        .doc(board.id);
    
    // Referencias a sus subcolecciones
    final listsRef = boardRef.collection('lists');
    final cardsRef = boardRef.collection('cards');

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Obtener y eliminar todas las tarjetas
      final cardsQuery = await cardsRef.get();
      for (final doc in cardsQuery.docs) {
        batch.delete(doc.reference);
      }

      // 2. Obtener y eliminar todas las listas
      final listsQuery = await listsRef.get();
      for (final doc in listsQuery.docs) {
        batch.delete(doc.reference);
      }

      // 3. Eliminar el tablero principal
      batch.delete(boardRef);

      // Ejecutar la eliminación en lote
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tablero "${board.title}" eliminado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el tablero: $e')),
        );
      }
    }
  }

  // --- AÑADIDO: Diálogo de confirmación ---
  void _showDeleteBoardDialog(BuildContext context, Board board) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Eliminar Tablero?'),
          content: Text('¿Estás seguro de que quieres eliminar "${board.title}"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                _deleteBoard(context, board); // Llama a la función de eliminar
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: board.color,
      child: InkWell(
        onTap: () {
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(board.icon, size: 28, color: Colors.white),
                  
                  // --- CAMBIO: Botones envueltos en un Row ---
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón de Estrella
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 24.0,
                        icon: Icon(
                          board.isStarred ? Icons.star : Icons.star_border,
                          size: 24,
                          color: board.isStarred ? Colors.yellowAccent : Colors.white70,
                        ),
                        onPressed: () {
                          _toggleStarStatus(context, board);
                        },
                      ),
                      
                      const SizedBox(width: 8),

                      // --- AÑADIDO: Menú de 3 puntos ---
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white70, size: 24.0),
                        tooltip: 'Opciones',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteBoardDialog(context, board);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline, color: Colors.red),
                              title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          // (Puedes añadir "Renombrar" aquí si quieres)
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                board.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// --- FIN DE CAMBIOS ---
// ===================================================================

class NewBoardCard extends StatelessWidget {
  // ... (Sin cambios)
  const NewBoardCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) => const CreateBoardDialog(),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 40, color: Colors.grey.shade600),
              const SizedBox(height: 8),
              Text(
                'Crear nuevo tablero',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkspacesSection extends StatelessWidget {
  // ... (Sin cambios)
  final List<Workspace> workspaces;
  const WorkspacesSection({super.key, required this.workspaces});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text('Espacios de trabajo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        ...workspaces.map((ws) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(Icons.rocket_launch, size: 32, color: Colors.indigo.shade500),
              title: Text(ws.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${ws.members} miembros - ${ws.boards} tableros', style: TextStyle(color: Colors.grey.shade600)),
              onTap: () {
                debugPrint('Navegando a Workspace: ${ws.name}');
              },
            ),
          ),
        )).toList(),
      ],
    );
  }
}