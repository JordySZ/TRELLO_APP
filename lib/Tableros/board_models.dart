import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para una Columna/Lista (ej: "TABLA 1")
class BoardList {
  final String id;
  final String title;
  final int position;

  BoardList({required this.id, required this.title, required this.position});

  factory BoardList.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BoardList(
      id: doc.id,
      title: data['title'] ?? 'Sin Título',
      position: data['position'] ?? 0,
    );
  }
}

// Modelo para una Tarjeta (ej: "Diseñar nueva landing")
class BoardCard {
  final String id;
  final String title;
  final String listId; // A qué lista pertenece
  final int position;
  // (Puedes añadir más campos aquí: description, labels, dueDate, etc.)

  BoardCard({
    required this.id, 
    required this.title, 
    required this.listId, 
    required this.position
  });

  factory BoardCard.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BoardCard(
      id: doc.id,
      title: data['title'] ?? '',
      listId: data['listId'] ?? '',
      position: data['position'] ?? 0,
    );
  }
}