import 'package:flutter/material.dart';
import 'board_models.dart';

class CardDetailsDialog extends StatelessWidget {
  final BoardCard card;
  const CardDetailsDialog({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.web_asset, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(card.title),
          ),
        ],
      ),
      content: SizedBox(
        width: 600, // Darle un ancho al diálogo
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descripción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Añadir una descripción más detallada...',
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
            // ... (Aquí puedes añadir checklists, etiquetas, etc.)
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}