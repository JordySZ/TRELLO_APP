import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _materiaController = TextEditingController();
  final _diaController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFinController = TextEditingController();
  
  final CollectionReference _horariosCollection =
      FirebaseFirestore.instance.collection('horarios');

  // Crear nuevo horario
  Future<void> _createHorario() async {
    if (_materiaController.text.isNotEmpty &&
        _diaController.text.isNotEmpty &&
        _horaInicioController.text.isNotEmpty &&
        _horaFinController.text.isNotEmpty) {
      await _horariosCollection.add({
        'materia': _materiaController.text,
        'dia': _diaController.text,
        'hora_inicio': _horaInicioController.text,
        'hora_fin': _horaFinController.text,
      });
      _materiaController.clear();
      _diaController.clear();
      _horaInicioController.clear();
      _horaFinController.clear();
    }
  }

  // Eliminar horario
  Future<void> _deleteHorario(String horarioId) async {
    await _horariosCollection.doc(horarioId).delete();
  }

  // Actualizar horario
  Future<void> _updateHorario(String horarioId) async {
    if (_materiaController.text.isNotEmpty &&
        _diaController.text.isNotEmpty &&
        _horaInicioController.text.isNotEmpty &&
        _horaFinController.text.isNotEmpty) {
      await _horariosCollection.doc(horarioId).update({
        'materia': _materiaController.text,
        'dia': _diaController.text,
        'hora_inicio': _horaInicioController.text,
        'hora_fin': _horaFinController.text,
      });
      _materiaController.clear();
      _diaController.clear();
      _horaInicioController.clear();
      _horaFinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CRUD Horario'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _materiaController,
              decoration: InputDecoration(
                labelText: 'Materia',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _diaController,
              decoration: InputDecoration(
                labelText: 'Día',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _horaInicioController,
              decoration: InputDecoration(
                labelText: 'Hora de inicio',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _horaFinController,
              decoration: InputDecoration(
                labelText: 'Hora de fin',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _createHorario,
                child: Text('Crear Horario'),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _horariosCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No hay horarios.'));
                }

                var horarios = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: horarios.length,
                  itemBuilder: (context, index) {
                    var horario = horarios[index];
                    return ListTile(
                      title: Text('${horario['materia']} - ${horario['dia']}'),
                      subtitle: Text(
                          '${horario['hora_inicio']} - ${horario['hora_fin']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteHorario(horario.id);
                        },
                      ),
                      onTap: () {
                        _materiaController.text = horario['materia'];
                        _diaController.text = horario['dia'];
                        _horaInicioController.text = horario['hora_inicio'];
                        _horaFinController.text = horario['hora_fin'];
                        // Aquí se puede implementar la lógica para actualizar
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
