import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AyudaSoportePage extends StatefulWidget {
  @override
  _AyudaSoportePageState createState() => _AyudaSoportePageState();
}

class _AyudaSoportePageState extends State<AyudaSoportePage> {
  final TextEditingController _asuntoController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();

  @override
  void dispose() {
    _asuntoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _enviarFormulario() async {
    final asunto = _asuntoController.text.trim();
    final mensaje = _mensajeController.text.trim();

    if (asunto.isEmpty || mensaje.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final nombreUsuario = userDoc['nombre'] ?? 'Usuario';

      await FirebaseFirestore.instance.collection('soporte').add({
        'nombre': nombreUsuario,
        'uid': user.uid,
        'asunto': asunto,
        'mensaje': mensaje,
        'fecha': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mensaje enviado correctamente.')),
      );

      _asuntoController.clear();
      _mensajeController.clear();
    } catch (e) {
      print('Error al enviar mensaje de soporte: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje. Inténtalo nuevamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayuda y Soporte'),
        backgroundColor: Color(0xFF1976D2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "¿Tienes un problema o duda?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Completa el siguiente formulario y nos pondremos en contacto contigo.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _asuntoController,
              decoration: InputDecoration(
                labelText: 'Asunto',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.blue.shade50,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _mensajeController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Mensaje',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.blue.shade50,
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _enviarFormulario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                icon: Icon(Icons.send),
                label: Text('Enviar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
