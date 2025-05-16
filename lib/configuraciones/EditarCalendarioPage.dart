import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditarCalendarioPage extends StatefulWidget {
  final Map<String, dynamic> calendario;
  final String docId;

  EditarCalendarioPage({required this.calendario, required this.docId});

  @override
  _EditarCalendarioPageState createState() => _EditarCalendarioPageState();
}

class _EditarCalendarioPageState extends State<EditarCalendarioPage> {
  final diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final horas = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00'
  ];

  late List<Map<String, dynamic>> materias;
  bool cambiosRealizados = false;
  String? userName; // <-- Aquí guardamos el nombre del usuario

  @override
  void initState() {
    super.initState();
    materias = List<Map<String, dynamic>>.from(widget.calendario['materias'] ?? []);
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      setState(() {
        userName = doc.data()?['nombre'] ?? 'Sin nombre';
      });
    }
  }

  int _horaAMin(String hora) =>
      int.parse(hora.split(':')[0]) * 60 + int.parse(hora.split(':')[1]);

  bool _horarioDisponible(String dia, String inicio, String fin,
      [Map<String, dynamic>? excluir]) {
    final ini = _horaAMin(inicio), fi = _horaAMin(fin);
    return !materias.any((m) {
      if (m == excluir || m['dia'] != dia) return false;
      final ei = _horaAMin(m['horaInicio']), ef = _horaAMin(m['horaFin']);
      return !(fi <= ei || ini >= ef);
    });
  }

  Future<void> _guardarFirestore() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('calendarios')
        .doc(widget.docId)
        .set({'materias': materias}, SetOptions(merge: true));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Cambios guardados')));
  }

  void _mostrarDialogoMateria({Map<String, dynamic>? materia}) {
    final nombreCtrl = TextEditingController(text: materia?['nombre']);
    final cursoCtrl = TextEditingController(text: materia?['curso']);
    String dia = materia?['dia'] ?? diasSemana.first;
    String horaInicio = materia?['horaInicio'] ?? horas.first;
    String horaFin = materia?['horaFin'] ??
        (horas.length > 1 ? horas[1] : horas.first);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(materia == null ? 'Agregar Materia' : 'Editar Materia'),
        content: StatefulBuilder(
          builder: (_, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: cursoCtrl,
                  decoration: InputDecoration(labelText: 'Curso'),
                ),
                DropdownButton<String>(
                  value: horaInicio,
                  onChanged: (v) => setState(() {
                    horaInicio = v!;
                    final idx = horas.indexOf(horaInicio);
                    if (horas.indexOf(horaFin) <= idx && idx + 1 < horas.length) {
                      horaFin = horas[idx + 1];
                    }
                  }),
                  items: horas
                      .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                      .toList(),
                ),
                DropdownButton<String>(
                  value: horaFin,
                  onChanged: (v) => setState(() => horaFin = v!),
                  items: horas
                      .where((h) => horas.indexOf(h) > horas.indexOf(horaInicio))
                      .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                      .toList(),
                ),
                DropdownButton<String>(
                  value: dia,
                  onChanged: (v) => setState(() => dia = v!),
                  items: diasSemana
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty || cursoCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Completa todos los campos')),
                );
                return;
              }

              if (!_horarioDisponible(dia, horaInicio, horaFin, materia)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Horario ocupado')),
                );
                return;
              }

              final nueva = {
                'nombre': nombreCtrl.text.trim(),
                'curso': cursoCtrl.text.trim(),
                'dia': dia,
                'horaInicio': horaInicio,
                'horaFin': horaFin,
              };

              setState(() {
                if (materia == null) {
                  materias.add(nueva);
                } else {
                  final i = materias.indexOf(materia);
                  if (i != -1) materias[i] = nueva;
                }
                cambiosRealizados = true;
              });

              await _guardarFirestore();
              Navigator.of(context).pop();
            },
            child: Text(materia == null ? 'Agregar' : 'Guardar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _eliminarMateria(Map<String, dynamic> materia) async {
    setState(() {
      materias.remove(materia);
      cambiosRealizados = true;
    });
    await _guardarFirestore();
  }

  @override
  void dispose() {
    if (cambiosRealizados) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pop(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(cambiosRealizados);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          title: Text('Editar Calendario'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.calendario['nombre'] ?? 'Calendario',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (userName != null)
                Text(
                  'Usuario: $userName',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              Divider(thickness: 2),
              Expanded(
                child: materias.isEmpty
                    ? Center(child: Text('No hay materias'))
                    : ListView.builder(
                        itemCount: materias.length,
                        itemBuilder: (_, i) {
                          final m = materias[i];
                          return Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                m['nombre'] ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  '${m['curso']} - ${m['dia']} ${m['horaInicio']} a ${m['horaFin']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () =>
                                        _mostrarDialogoMateria(materia: m),
                                  ),
                                  IconButton(
                                    icon:
                                        Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarMateria(m),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _mostrarDialogoMateria(),
          backgroundColor: Colors.blue[700],
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
