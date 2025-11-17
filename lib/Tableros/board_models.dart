import 'package:cloud_firestore/cloud_firestore.dart';

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

class BoardCard {
  final String id;
  final String title;
  final String listId;
  final int position;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final List<Map<String, dynamic>> subtasks;
  // --- NUEVO CAMPO ---
  final String description; 

  BoardCard({
    required this.id, 
    required this.title, 
    required this.listId, 
    required this.position,
    this.startDate,
    this.endDate,
    this.status = 'pendiente',
    this.subtasks = const [],
    this.description = '', // Valor por defecto vacío
  });

  factory BoardCard.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    return BoardCard(
      id: doc.id,
      title: data['title'] ?? '',
      listId: data['listId'] ?? '',
      position: data['position'] ?? 0,
      startDate: data['startDate'] != null ? (data['startDate'] as Timestamp).toDate() : null,
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'pendiente',
      subtasks: data['subtasks'] != null 
          ? List<Map<String, dynamic>>.from(data['subtasks']) 
          : [],
      // Leer descripción (si no existe, devuelve string vacío)
      description: data['description'] ?? '', 
    );
  }
}