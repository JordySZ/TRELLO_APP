import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_app/home/app_drawer.dart'show BoardListItemData;
import 'package:flutter/material.dart';
import 'board_models.dart';
import 'card_details_dialog.dart';
// --- AÑADIDO: Importamos el modelo de item de app_drawer.dart ---


// --- BoardScreen (Sin cambios) ---
class BoardScreen extends StatefulWidget {
// ... (código existente sin cambios)
  final String boardId;
  final String boardTitle;
  final Color boardColor;

  const BoardScreen({
    super.key,
    required this.boardId,
    required this.boardTitle,
    required this.boardColor,
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

// --- _BoardScreenState (Nuevas funciones añadidas) ---
class _BoardScreenState extends State<BoardScreen> {
  late final String _userId;
// ... (código existente sin cambios)
  late final CollectionReference _listsRef;
  late final CollectionReference _cardsRef;
  
  // --- AÑADIDO: Stream para el menú de tableros ---
  late final User? _user;
  late final Stream<QuerySnapshot>? _boardsStream;


  @override
  void initState() {
// ... (código existente sin cambios)
    super.initState();
    _user = FirebaseAuth.instance.currentUser; // <--- AÑADIDO
    _userId = _user!.uid; 
    _listsRef = FirebaseFirestore.instance
// ... (código existente sin cambios)
        .collection('users')
        .doc(_userId)
        .collection('boards')
        .doc(widget.boardId)
        .collection('lists');
    
    _cardsRef = FirebaseFirestore.instance
// ... (código existente sin cambios)
        .collection('users')
        .doc(_userId)
        .collection('boards')
        .doc(widget.boardId)
        .collection('cards');

    // --- AÑADIDO: Inicializamos el stream de tableros ---
    _boardsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('boards')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _addList(String title) async {
// ... (código existente sin cambios)
    final query = await _listsRef.orderBy('position', descending: true).limit(1).get();
    final int nextPosition = query.docs.isEmpty ? 0 : (query.docs.first['position'] as int) + 1;
    
    await _listsRef.add({
      'title': title,
      'position': nextPosition,
    });
  }

  Future<void> _addCard(String title, String listId) async {
// ... (código existente sin cambios)
    final query = await _cardsRef.where('listId', isEqualTo: listId).orderBy('position', descending: false).get();
    final int nextPosition = query.docs.isEmpty ? 0 : (query.docs.last.get('position') as int) + 1;

    await _cardsRef.add({
// ... (código existente sin cambios)
      'title': title,
      'listId': listId,
      'position': nextPosition,
    });
  }

  // ===================================================================
// ... (código existente sin cambios)
  // --- INICIO DE NUEVAS FUNCIONES CRUD ---
  // ===================================================================

  /// UPDATE: Renombra una lista
// ... (código existente sin cambios)
  Future<void> _renameList(String listId, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    await _listsRef.doc(listId).update({'title': newTitle.trim()});
  }

  /// DELETE: Elimina una lista Y TODAS SUS TARJETAS
// ... (código existente sin cambios)
  Future<void> _deleteList(String listId) async {
    try {
      // Usamos un batch para eliminar todo en una sola operación
      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Encontrar todas las tarjetas en la lista
// ... (código existente sin cambios)
      final cardsQuery = await _cardsRef.where('listId', isEqualTo: listId).get();
      
      // 2. Marcar todas esas tarjetas para eliminación
      for (final doc in cardsQuery.docs) {
// ... (código existente sin cambios)
        batch.delete(doc.reference);
      }
      
      // 3. Marcar la lista misma para eliminación
// ... (código existente sin cambios)
      batch.delete(_listsRef.doc(listId));
      
      // 4. Ejecutar la operación
      await batch.commit();

    } catch (e) {
// ... (código existente sin cambios)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  /// Muestra el diálogo para Renombrar
// ... (código existente sin cambios)
  void _showRenameListDialog(BoardList list) {
    final controller = TextEditingController(text: list.title);
    showDialog(
      context: context,
// ... (código existente sin cambios)
      builder: (context) {
        return AlertDialog(
          title: const Text('Renombrar Lista'),
// ... (código existente sin cambios)
          content: TextField(
            controller: controller,
            autofocus: true,
// ... (código existente sin cambios)
            decoration: const InputDecoration(hintText: 'Nuevo nombre de la lista'),
            onSubmitted: (_) {
              _renameList(list.id, controller.text);
// ... (código existente sin cambios)
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
// ... (código existente sin cambios)
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancelar')
            ),
            ElevatedButton(
              onPressed: () {
// ... (código existente sin cambios)
                _renameList(list.id, controller.text);
                Navigator.pop(context);
              }, 
              child: const Text('Guardar')
            ),
          ],
        );
      }
    );
  }

  /// Muestra el diálogo de confirmación para Eliminar
// ... (código existente sin cambios)
  void _showDeleteListDialog(BoardList list) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
// ... (código existente sin cambios)
          title: Text('¿Eliminar Lista?'),
          content: Text('¿Estás seguro de que quieres eliminar "${list.title}"? Todas las tarjetas en esta lista también serán eliminadas permanentemente.'),
          actions: [
            TextButton(
// ... (código existente sin cambios)
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancelar')
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
// ... (código existente sin cambios)
                _deleteList(list.id);
                Navigator.pop(context);
              }, 
              child: const Text('Eliminar')
            ),
          ],
        );
      }
    );
  }

  // ===================================================================
// ... (código existente sin cambios)
  // --- FIN DE NUEVAS FUNCIONES CRUD ---
  // ===================================================================

  @override
  Widget build(BuildContext context) {
// ... (código existente sin cambios)
    // ... (build sin cambios)
    final Color darkColor = HSLColor.fromColor(widget.boardColor).withLightness(0.3).toColor();
    final Color darkerColor = HSLColor.fromColor(widget.boardColor).withLightness(0.2).toColor();

    return Scaffold(
// ... (código existente sin cambios)
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
// ... (código existente sin cambios)
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkColor, darkerColor],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _buildListsArea(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // ... (appBar sin cambios)
    return AppBar(
      title: Text(widget.boardTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
// ... (código existente sin cambios)
      backgroundColor: Colors.white.withOpacity(0.1),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      actions: [
        // ===================================================================
        // --- INICIO DEL CÓDIGO MODIFICADO ---
        // ===================================================================
        StreamBuilder<QuerySnapshot>(
          stream: _boardsStream, // Stream del 'initState'
          builder: (context, snapshot) {
            // Mientras carga, muestra un botón deshabilitado
            if (!snapshot.hasData) {
              return TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white.withOpacity(0.7)),
                icon: const Icon(Icons.dashboard_outlined, size: 16),
                label: const Text('Tableros'),
                onPressed: null, // Deshabilitado
              );
            }
            
            // Mapea los documentos a nuestro modelo simple
            final boards = snapshot.data!.docs.map((doc) => BoardListItemData.fromFirestore(doc)).toList();

            return PopupMenuButton<BoardListItemData>(
              // Cuando se selecciona un tablero...
              onSelected: (selectedBoard) {
// ... (código existente sin cambios)
                // Si el usuario selecciona el tablero en el que YA ESTÁ, no hacemos nada.
                if (selectedBoard.id == widget.boardId) return;

                // Si es un tablero diferente, reemplazamos la pantalla actual
                Navigator.pushReplacement(
// ... (código existente sin cambios)
                  context,
                  MaterialPageRoute(
                    // Creamos una NUEVA pantalla del tablero con los datos del tablero seleccionado
                    builder: (context) => BoardScreen(
// ... (código existente sin cambios)
                      boardId: selectedBoard.id,
                      boardTitle: selectedBoard.title,
                      boardColor: selectedBoard.color,
                    ),
                  ),
                );
              },
              // --- CAMBIO AQUÍ: Reemplazamos TextButton.icon por un Row con Padding ---
              // Este es el widget que el usuario toca para abrir el menú
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Padding para el área táctil
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.dashboard_outlined, size: 16, color: Colors.white),
                    const SizedBox(width: 8.0),
                    const Text('Tableros', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              // --- FIN DEL CAMBIO ---

              // Esta es la lista que se despliega
              itemBuilder: (context) {
// ... (código existente sin cambios)
                return boards.map((board) {
                  final bool isCurrentBoard = board.id == widget.boardId;
                  return PopupMenuItem<BoardListItemData>(
                    value: board,
                    child: Row(
// ... (código existente sin cambios)
                      children: [
                        // Cuadrito de color
                        Container(width: 12, height: 12, color: board.color, margin: const EdgeInsets.only(right: 12)),
                        // Título
                        Text(
// ... (código existente sin cambios)
                          board.title,
                          style: isCurrentBoard 
                              ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) 
                              : null,
                        ),
                        const Spacer(),
                        // Check si es el tablero actual
                        if (isCurrentBoard)
                          const Icon(Icons.check, color: Colors.blue, size: 18)
                      ],
                    ),
                  );
                }).toList();
              },
            );
          },
        ),
        // ===================================================================
        // --- FIN DEL CÓDIGO MODIFICADO ---
        // ===================================================================

        IconButton(icon: const Icon(Icons.star_border), onPressed: () {}),
        TextButton.icon(
// ... (código existente sin cambios)
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          icon: const Icon(Icons.people_outline),
          label: const Text('Equipo'),
          onPressed: () {},
        ),
        IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
      ],
    );
  }

  Widget _buildListsArea() {
    return StreamBuilder<QuerySnapshot>(
// ... (código existente sin cambios)
      stream: _listsRef.orderBy('position').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
// ... (código existente sin cambios)
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { // <-- CAMBIO: !snapshot.hasData
          // Antes estaba !snapshot.hasData, lo que es incorrecto si hay 0 listas
          return ListView( // Permite añadir la primera lista
// ... (código existente sin cambios)
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- AÑADIDO: Key para arreglar el bug de estado ---
              _AddListWidget(
                key: const ValueKey('__add_list_widget__'),
                onAddList: _addList
              )
            ],
          );
        }

        final lists = snapshot.data!.docs.map((doc) => BoardList.fromFirestore(doc)).toList();

        return ListView.builder(
// ... (código existente sin cambios)
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16.0),
          itemCount: lists.length + 1,
          itemBuilder: (context, index) {
            if (index == lists.length) {
              return _AddListWidget(
                // --- AÑADIDO: Key para arreglar el bug de estado ---
                key: const ValueKey('__add_list_widget__'),
                onAddList: _addList
              );
            }
            final list = lists[index];
// ... (código existente sin cambios)
            return _ListColumn(
              list: list,
              cardsRef: _cardsRef,
// ... (código existente sin cambios)
              onAddCard: (title) => _addCard(title, list.id),
              // --- AÑADIDO: Pasamos las funciones de CRUD ---
              onRename: () => _showRenameListDialog(list),
              onDelete: () => _showDeleteListDialog(list),
            );
          },
        );
      },
    );
  }
}

// --- _ListColumn (Actualizado con PopupMenuButton) ---
class _ListColumn extends StatefulWidget {
// ... (código existente sin cambios)
  final BoardList list;
  final CollectionReference cardsRef;
  final Future<void> Function(String title) onAddCard;
// ... (código existente sin cambios)
  final VoidCallback onRename; // <-- NUEVO
  final VoidCallback onDelete; // <-- NUEVO

  const _ListColumn({
    required this.list,
// ... (código existente sin cambios)
    required this.cardsRef,
    required this.onAddCard,
    required this.onRename, // <-- NUEVO
    required this.onDelete, // <-- NUEVO
  });

  @override
  State<_ListColumn> createState() => _ListColumnState();
}

class _ListColumnState extends State<_ListColumn> {
  @override
  Widget build(BuildContext context) {
    return Container(
// ... (código existente sin cambios)
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
// ... (código existente sin cambios)
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
// ... (código existente sin cambios)
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la lista
          Padding(
// ... (código existente sin cambios)
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
// ... (código existente sin cambios)
              children: [
                // --- CAMBIO: Título envuelto en Expanded ---
                Expanded(
                  child: Text(
                    widget.list.title.toUpperCase(),
// ... (código existente sin cambios)
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis, // Evita overflow si el título es largo
                  ),
                ),
                // --- CAMBIO: IconButton reemplazado por PopupMenuButton ---
                PopupMenuButton<String>(
// ... (código existente sin cambios)
                  icon: const Icon(Icons.more_horiz, color: Colors.black54),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'rename') {
// ... (código existente sin cambios)
                      widget.onRename();
                    } else if (value == 'delete') {
                      widget.onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
// ... (código existente sin cambios)
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(Icons.edit, size: 20),
                        title: Text('Renombrar Lista'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
// ... (código existente sin cambios)
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red, size: 20),
                        title: Text('Eliminar Lista', style: TextStyle(color: Colors.red)),
                        dense: true,
// ... (código existente sin cambios)
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // StreamBuilder de Tarjetas (Sin cambios)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.cardsRef
                  .where('listId', isEqualTo: widget.list.id)
// ... (código existente sin cambios)
                  .orderBy('position')
                  .snapshots(),
              builder: (context, snapshot) {
                
                if (snapshot.connectionState == ConnectionState.waiting) {
// ... (código existente sin cambios)
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
// ... (código existente sin cambios)
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }
                if (snapshot.hasData) {
// ... (código existente sin cambios)
                  final cards = snapshot.data!.docs.map((doc) => BoardCard.fromFirestore(doc)).toList();
                  if (cards.isEmpty) {
                    return const SizedBox.shrink(); 
                  }
                  return ListView.builder(
// ... (código existente sin cambios)
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      return _CardItem(card: cards[index]);
                    },
                  );
                }
                return const Center(child: Text('Algo salió mal'));
              },
            ),
          ),

          // Botón de "Añadir una tarjeta" (Sin cambios)
          _AddCardWidget(onAddCard: widget.onAddCard),
        ],
      ),
    );
  }
}

// --- _CardItem (Sin cambios) ---
class _CardItem extends StatelessWidget {
// ... (código existente sin cambios)
  final BoardCard card;
  const _CardItem({required this.card});

  @override
  Widget build(BuildContext context) {
// ... (código existente sin cambios)
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        onTap: () {
          showDialog(
// ... (código existente sin cambios)
            context: context,
            builder: (context) => CardDetailsDialog(card: card),
          );
        },
        child: Container(
          width: double.infinity,
// ... (código existente sin cambios)
          padding: const EdgeInsets.all(12.0),
          child: Text(card.title),
        ),
      ),
    );
  }
}

// --- _AddListWidget (Sin cambios) ---
class _AddListWidget extends StatefulWidget {
  final Future<void> Function(String title) onAddList;
  // --- AÑADIDO: Key al constructor ---
  const _AddListWidget({super.key, required this.onAddList});

  @override
  State<_AddListWidget> createState() => _AddListWidgetState();
}

class _AddListWidgetState extends State<_AddListWidget> {
  final _controller = TextEditingController();
// ... (código existente sin cambios)
  bool _isAdding = false;
  bool _isLoading = false;

  void _submit() async {
    if (_controller.text.trim().isEmpty) {
// ... (código existente sin cambios)
      setState(() => _isAdding = false);
      return;
    }
    setState(() => _isLoading = true);
    await widget.onAddList(_controller.text.trim());
    
    if (mounted) {
// ... (código existente sin cambios)
      setState(() {
        _isLoading = false;
        _isAdding = false;
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
// ... (código existente sin cambios)
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: _isAdding
          ? Container(
// ... (código existente sin cambios)
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  TextField(
// ... (código existente sin cambios)
                    controller: _controller,
                    autofocus: true,
                    decoration: const InputDecoration(
// ... (código existente sin cambios)
                      hintText: 'Introduce el título de la lista...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Añadir'),
// ... (código existente sin cambios)
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _isAdding = false),
                      )
                    ],
                  ),
                ],
              ),
            )
          : InkWell(
              onTap: () => setState(() => _isAdding = true),
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                decoration: BoxDecoration(
// ... (código existente sin cambios)
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
// ... (código existente sin cambios)
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Añadir otra lista', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// --- _AddCardWidget (Sin cambios) ---
class _AddCardWidget extends StatefulWidget {
  final Future<void> Function(String title) onAddCard;
// ... (código existente sin cambios)
  const _AddCardWidget({required this.onAddCard});

  @override
  State<_AddCardWidget> createState() => _AddCardWidgetState();
}

class _AddCardWidgetState extends State<_AddCardWidget> {
  final _controller = TextEditingController();
// ... (código existente sin cambios)
  bool _isAdding = false;
  bool _isLoading = false;

  void _submit() async {
    if (_controller.text.trim().isEmpty) {
// ... (código existente sin cambios)
      setState(() => _isAdding = false);
      return;
    }
    setState(() => _isLoading = true);
    await widget.onAddCard(_controller.text.trim());
    
    if (mounted) {
// ... (código existente sin cambios)
      setState(() {
        _isLoading = false;
        _isAdding = false;
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
// ... (código existente sin cambios)
          children: [
            Card(
              elevation: 1,
              child: TextField(
                controller: _controller,
// ... (código existente sin cambios)
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Introduce un título para esta tarjeta...',
                  border: InputBorder.none,
// ... (código existente sin cambios)
                  contentPadding: EdgeInsets.all(12.0),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Añadir'),
// ... (código existente sin cambios)
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _isAdding = false),
                )
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
// ... (código existente sin cambios)
      padding: const EdgeInsets.all(8.0),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black54,
// ... (código existente sin cambios)
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Añadir una tarjeta'),
        onPressed: () => setState(() => _isAdding = true),
      ),
    );
  }
}