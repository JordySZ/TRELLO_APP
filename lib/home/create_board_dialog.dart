import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- Listas de Opciones para el Diálogo ---

// Lista de iconos que coinciden con tu imagen
const List<IconData> _availableIcons = [
  Icons.article_outlined, // Documento
  Icons.assessment_outlined, // Gráfico de barras
  Icons.lightbulb_outline, // Bombilla
  Icons.group_outlined, // Grupo
  Icons.rocket_launch_outlined, // Cohete
  Icons.lightbulb, // Bombilla (sólida - alternativa)
  Icons.phone_android_outlined, // Móvil
  Icons.monetization_on_outlined, // Dinero (no está en la img, pero es útil)
  Icons.shield_outlined, // Escudo (no está, pero es útil)
  Icons.pie_chart_outline, // Gráfico de pastel
  Icons.bolt_outlined, // Rayo
  Icons.key_outlined, // Llave
  Icons.book_outlined, // Libro
  Icons.movie_outlined, // Película
  Icons.music_note_outlined, // Música
  Icons.business_center_outlined, // Maletín
  Icons.flare_outlined, // Estrella/Brillo
  Icons.fireplace_outlined, // Fuego
  Icons.diamond_outlined, // Diamante
  Icons.gamepad_outlined, // Mando
  Icons.home_outlined, // Casa
  Icons.airplanemode_active_outlined, // Avión
  Icons.wb_sunny_outlined, // Sol (no está, pero es útil)
];

// Lista de colores que coinciden con tu imagen
const List<Color> _availableColors = [
  Color(0xFF1E88E5), // Azul
  Color(0xFF00C853), // Verde
  Color(0xFFD500F9), // Morado
  Color(0xFFFF3D00), // Naranja Oscuro
  Color(0xFFE91E63), // Rosa
  Color(0xFFFF1744), // Rojo
  Color(0xFF00BFA5), // Turquesa
  Color(0xFF651FFF), // Índigo
  Color(0xFFFF9100), // Naranja
  Color(0xFF00E5FF), // Cian
  Color(0xFF76FF03), // Lima
  Color(0xFF6D4C41), // Marrón (no está, pero es útil)
];


// --- Widget del Diálogo ---

class CreateBoardDialog extends StatefulWidget {
  const CreateBoardDialog({super.key});

  @override
  State<CreateBoardDialog> createState() => _CreateBoardDialogState();
}

class _CreateBoardDialogState extends State<CreateBoardDialog> {
  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores y estado local
  final _titleController = TextEditingController();
  IconData _selectedIcon = _availableIcons.first;
  Color _selectedColor = _availableColors.first;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el título para actualizar la vista previa
    _titleController.addListener(() {
      setState(() {
        // No es necesario hacer nada aquí, solo forzar la reconstrucción
        // del widget de vista previa (que escucha al controlador).
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// -----------------------------------------------------------------
  /// Lógica para crear el tablero en Firebase
  /// -----------------------------------------------------------------
  Future<void> _createBoard() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return; // Si el título está vacío, no hacer nada
    }

    // 2. Mostrar indicador de carga
    setState(() => _isLoading = true);

    try {
      // 3. Obtener el usuario actual
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Usuario no autenticado.");
      }

      // 4. Preparar los datos
      final newBoard = {
        'title': _titleController.text,
        'colorHex': _selectedColor.value.toRadixString(16).substring(2), // Guarda el color como "1E88E5"
        'iconCodePoint': _selectedIcon.codePoint, // Guarda el icono como un número
        'isStarred': false,
        'ownerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(), // Para ordenar por fecha
      };

      // 5. Guardar en Firestore en la subcolección del usuario
      // ESTRUCTURA: users/{userId}/boards/{boardId}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('boards')
          .add(newBoard);

      // 6. Cerrar el diálogo si todo salió bien
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // 7. Manejar errores
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el tablero: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Usar Stack para poner el indicador de carga por encima
      content: Stack(
        clipBehavior: Clip.none,
        children: [
          // Contenido del formulario
          SizedBox(
            width: 500, // Ancho fijo para el diálogo
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Título y botón de cerrar ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Crear nuevo tablero',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Personaliza tu tablero eligiendo un nombre, color e icono',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // --- Nombre del tablero ---
                    const Text('Nombre del tablero', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Ej: Marketing Digital, Proyecto 2024...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- Selector de Icono ---
                    const Text('Icono', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildIconSelector(),
                    const SizedBox(height: 24),

                    // --- Selector de Color ---
                    const Text('Color del tablero', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildColorSelector(),
                    const SizedBox(height: 24),

                    // --- Vista Previa ---
                    const Text('Vista previa', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildPreview(),
                    const SizedBox(height: 32),

                    // --- Botones de Acción ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _createBoard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Crear tablero'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // --- Indicador de Carga (Overlay) ---
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.7),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
      // Quitar el padding por defecto del AlertDialog
      contentPadding: const EdgeInsets.all(24.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
    );
  }

  // --- Widgets de construcción (helpers) ---

  Widget _buildIconSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _availableIcons.map((icon) {
          final bool isSelected = icon == _selectedIcon;
          return InkWell(
            onTap: () => setState(() => _selectedIcon = icon),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _availableColors.map((color) {
        final bool isSelected = color == _selectedColor;
        return InkWell(
          onTap: () => setState(() => _selectedColor = color),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: Colors.black.withOpacity(0.5),
                      width: 3,
                    )
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreview() {
    // Este widget simula tu `_BoardCard`
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _selectedColor,
      child: SizedBox(
        height: 120, // Altura fija para la vista previa
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
                  Icon(_selectedIcon, size: 28, color: Colors.white),
                  const Icon(Icons.star_border, size: 24, color: Colors.white54), // Simulamos la estrella
                ],
              ),
              Text(
                _titleController.text.isEmpty ? 'Nombre del tablero' : _titleController.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}