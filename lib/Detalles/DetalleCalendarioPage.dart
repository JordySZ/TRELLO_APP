import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_app/Detalles/ediEstudiante.dart';

class DetalleCalendarioEstudiantePage extends StatefulWidget {
  final Map<String, dynamic> calendario;

  DetalleCalendarioEstudiantePage({required this.calendario});

  @override
  _DetalleCalendarioEstudiantePageState createState() =>
      _DetalleCalendarioEstudiantePageState();
}

class _DetalleCalendarioEstudiantePageState
    extends State<DetalleCalendarioEstudiantePage> {
  final List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<String> horas = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00'
  ];

  late List<Map<String, dynamic>> materias;
  String? nombreUsuario;

  late Map<String, dynamic> calendarioLocal;

  @override
  void initState() {
    super.initState();

    calendarioLocal = Map<String, dynamic>.from(widget.calendario);

    final materiasRaw = calendarioLocal['materias'];
    materias = [];

    try {
      materias = List<Map<String, dynamic>>.from(materiasRaw ?? []);
    } catch (e) {
      print('Error al convertir materias: $e');
      materias = [];
    }

    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    try {
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
    } catch (e) {
      print('Error al cargar nombre usuario: $e');
      setState(() {
        nombreUsuario = 'Error al cargar nombre';
      });
    }
  }

  List<List<Map<String, dynamic>?>> obtenerCalendario(List<Map<String, dynamic>> materias) {
    List<List<Map<String, dynamic>?>> calendario = List.generate(5, (_) => List.filled(horas.length, null));

    for (var materia in materias) {
      int diaIndex = diasSemana.indexOf(materia['dia']);
      int inicio = horas.indexOf(materia['horaInicio']);
      int fin = horas.indexOf(materia['horaFin']);
      if (diaIndex == -1 || inicio == -1 || fin == -1) continue;

      for (int i = inicio; i < fin; i++) {
        calendario[diaIndex][i] = materia;
      }
    }

    return calendario;
  }

  Future<void> _recargarCalendario() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final idDelCalendario = calendarioLocal['id'] ?? '';
    if (idDelCalendario.isEmpty) {
      print('⚠️ ID del calendario no encontrado en recarga.');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('calendarios')
          .doc(idDelCalendario)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          calendarioLocal = doc.data()!;

          // Aseguramos mantener el id
          calendarioLocal['id'] = doc.id;

          final materiasRaw = calendarioLocal['materias'];
          try {
            materias = List<Map<String, dynamic>>.from(materiasRaw ?? []);
          } catch (e) {
            print('Error al convertir materias tras recarga: $e');
            materias = [];
          }
        });
      } else {
        print('Documento no existe en Firestore');
      }
    } catch (e) {
      print('Error al recargar calendario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nombre = calendarioLocal['nombre'] ?? 'Sin nombre';
    final String usuario = nombreUsuario ?? 'Cargando usuario...';
    final tabla = obtenerCalendario(materias);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle Calendario Estudiante'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final idDelCalendario = calendarioLocal['id'] ?? '';

              if (idDelCalendario.isEmpty) {
                print('⚠️ ID del calendario no encontrado.');
                return;
              }

              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditarCalendarioPage(
                    calendario: Map<String, dynamic>.from(calendarioLocal),
                    docId: idDelCalendario,
                  ),
                ),
              );

              if (resultado != null) {
                // Recargamos calendario desde Firestore para tener datos actualizados
                await _recargarCalendario();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1200,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📅 Nombre: $nombre', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text('👤 Usuario: $usuario', style: TextStyle(fontSize: 22)),
                  SizedBox(height: 24),
                  DataTable(
                    columnSpacing: 40,
                    dataRowHeight: 120,
                    headingRowHeight: 70,
                    dataTextStyle: TextStyle(fontSize: 18),
                    headingTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    columns: [
                      DataColumn(
                        label: Container(
                          width: 140,
                          color: Colors.grey.shade300,
                          padding: EdgeInsets.all(8),
                          child: Text('Hora'),
                        ),
                      ),
                      ...diasSemana.map(
                        (dia) => DataColumn(
                          label: Container(
                            width: 180,
                            color: Colors.lightBlue.shade100,
                            padding: EdgeInsets.all(8),
                            child: Text(dia),
                          ),
                        ),
                      ),
                    ],
                    rows: List.generate(horas.length - 1, (horaIndex) {
                      final horaInicio = horas[horaIndex];
                      final horaFin = horas[horaIndex + 1];
                      final rango = '$horaInicio - $horaFin';

                      return DataRow(cells: [
                        DataCell(
                          Container(
                            width: 140,
                            color: Colors.grey.shade200,
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Text(rango),
                          ),
                        ),
                        ...List.generate(diasSemana.length, (diaIndex) {
                          final materia = tabla[diaIndex][horaIndex];
                          if (materia == null) return DataCell(SizedBox(width: 180));

                          return DataCell(
                            Container(
                              width: 180,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      materia['nombre'] ?? '',
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text('Curso: ${materia['curso'] ?? '-'}', style: TextStyle(fontSize: 15)),
                                    Text('Profesor: ${materia['profesor'] ?? '-'}', style: TextStyle(fontSize: 15)),
                                    Text('Aula: ${materia['aula'] ?? '-'}', style: TextStyle(fontSize: 15)),
                                    Text('Tipo: ${materia['tipoClase'] ?? '-'}', style: TextStyle(fontSize: 15)),
                                  ],
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
        ),
      ),
    );
  }
}
