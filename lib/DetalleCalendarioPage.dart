import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'configuraciones/EditarCalendarioPage.dart';

class DetalleCalendarioPage extends StatefulWidget {
  final Map<String, dynamic> calendario;
  final String calendarioDocId;

  DetalleCalendarioPage({required this.calendario, required this.calendarioDocId});

  @override
  _DetalleCalendarioPageState createState() => _DetalleCalendarioPageState();
}

class _DetalleCalendarioPageState extends State<DetalleCalendarioPage> {
  final List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<String> horas = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00'
  ];

  Map<String, dynamic> calendario = {};
  String? nombreUsuario;

  @override
  void initState() {
    super.initState();
    calendario = Map<String, dynamic>.from(widget.calendario);
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        nombreUsuario = userDoc.data()!['nombre'] ?? 'Sin nombre';
      });
    } else {
      setState(() {
        nombreUsuario = 'Sin nombre';
      });
    }
  }

  Future<void> _recargarDesdeFirestore() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('calendarios')
        .doc(widget.calendarioDocId);

    final snapshot = await docRef.get();
    if (snapshot.exists) {
      setState(() {
        calendario = snapshot.data()!;
      });
    }
  }

  List<List<Map<String, dynamic>?>> obtenerCalendario(List<dynamic> materias) {
    List<List<Map<String, dynamic>?>> tabla = List.generate(5, (_) => List.filled(horas.length, null));

    for (var mat in materias) {
      final materia = Map<String, dynamic>.from(mat);
      int diaIndex = diasSemana.indexOf(materia['dia']);
      int inicio = horas.indexOf(materia['horaInicio']);
      int fin = horas.indexOf(materia['horaFin']);
      if (diaIndex == -1 || inicio == -1 || fin == -1) continue;

      for (int i = inicio; i < fin; i++) {
        tabla[diaIndex][i] = materia;
      }
    }

    return tabla;
  }

  @override
  Widget build(BuildContext context) {
    final String nombre = calendario['nombre'] ?? 'Sin nombre';
    final String usuario = nombreUsuario ?? 'Cargando usuario...';
    final List<dynamic> materiasGuardadas = calendario['materias'] ?? [];
    final List<Map<String, dynamic>> materias = List<Map<String, dynamic>>.from(materiasGuardadas);
    final tabla = obtenerCalendario(materias);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Calendario'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final actualizado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditarCalendarioPage(
                    calendario: calendario,
                    docId: widget.calendarioDocId,
                  ),
                ),
              );

              if (actualizado == true) {
                await _recargarDesdeFirestore();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📅 Nombre: $nombre', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('👤 Usuario: $usuario', style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),

              DataTable(
                columnSpacing: 16,
                dataTextStyle: TextStyle(fontSize: 14),
                headingTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                columns: [
                  DataColumn(
                    label: Container(
                      color: Colors.grey.shade300,
                      padding: EdgeInsets.all(8),
                      child: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  ...diasSemana.map(
                    (dia) => DataColumn(
                      label: Container(
                        color: Colors.lightBlue.shade100,
                        padding: EdgeInsets.all(8),
                        child: Text(dia, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  )
                ],
                rows: List.generate(horas.length - 1, (horaIndex) {
                  final horaInicio = horas[horaIndex];
                  final horaFin = horas[horaIndex + 1];
                  final rango = '$horaInicio - $horaFin';

                  return DataRow(cells: [
                    DataCell(
                      Container(
                        color: Colors.grey.shade200,
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Text(rango, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    ...List.generate(diasSemana.length, (diaIndex) {
                      final materia = tabla[diaIndex][horaIndex];
                      if (materia == null) return DataCell(SizedBox());

                      return DataCell(
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            '${materia['nombre']} (${materia['curso']})',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                  ]);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
