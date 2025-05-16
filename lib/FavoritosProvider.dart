import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritosProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _favoritos = [];

  List<Map<String, dynamic>> get favoritos => _favoritos;

  // Carga inicial desde Firestore
  Future<void> cargarFavoritos(String usuarioId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Calendarios Profesor')
          .where('usuario', isEqualTo: usuarioId)
          .get();

      _favoritos.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // guardar id doc
        _favoritos.add(data);
      }
      notifyListeners();
    } catch (e) {
      print('Error cargando favoritos: $e');
    }
  }

  void agregarFavorito(Map<String, dynamic> calendario) {
    if (!_favoritos.any((fav) => fav['id'] == calendario['id'])) {
      _favoritos.add(calendario);
      notifyListeners();
    }
  }

  void quitarFavorito(Map<String, dynamic> calendario) {
    _favoritos.removeWhere((fav) => fav['id'] == calendario['id']);
    notifyListeners();
  }
}
