import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'materia.dart';
import '../../seleccion_tipo_page.dart';
import '../calguardados.dart';
import '../../favoritos_page.dart';

class HorarioTable extends StatefulWidget {
  final List<Materia> materias;
  final Function(Materia)? onEliminar;

  HorarioTable({
    required this.materias,
    this.onEliminar,
  });

  @override
  _HorarioTableState createState() => _HorarioTableState();
}

class _HorarioTableState extends State<HorarioTable> {
  int _selectedIndex = 0;

  final List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<String> horas = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00'
  ];

  List<List<Materia?>> obtenerCalendario() {
    List<List<Materia?>> calendario = List.generate(5, (_) => List.filled(horas.length, null));

    for (var materia in widget.materias) {
      int diaIndex = diasSemana.indexOf(materia.dia);
      int inicio = horas.indexOf(materia.horaInicio);
      int fin = horas.indexOf(materia.horaFin);
      if (diaIndex == -1 || inicio == -1 || fin == -1) continue;

      for (int i = inicio; i < fin; i++) {
        calendario[diaIndex][i] = materia;
      }
    }

    return calendario;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SeleccionTipoPage()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CalendariosGuardadosPage()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => FavoritosPage()));
        break;
    }
  }

  Future<String?> _mostrarCuadroTexto(BuildContext context) {
    TextEditingController controlador = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ingrese el nombre del calendario'),
          content: TextField(
            controller: controlador,
            decoration: InputDecoration(hintText: 'Nombre del calendario'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(controlador.text.trim()),
              child: Text('Guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> guardarCalendarioEnFirestore(String nombre, List<Materia> materias) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final materiasData = materias.map((m) => {
        'nombre': m.nombre,
        'curso': m.curso,
        'dia': m.dia,
        'horaInicio': m.horaInicio,
        'horaFin': m.horaFin,
      }).toList();

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('calendarios')
          .add({
        'nombre': nombre,
        'materias': materiasData,
        'tipo': 'profesor', // o 'estudiante', según el caso
        'fecha': FieldValue.serverTimestamp(),
      });

      print('✅ Calendario guardado en Firestore');
    } catch (e) {
      print('❌ Error al guardar en Firestore: $e');
    }
  }

  void _guardarCalendario() async {
    final materias = widget.materias;
    String? nombreCalendario = await _mostrarCuadroTexto(context);

    if (nombreCalendario != null && nombreCalendario.isNotEmpty) {
      await guardarCalendarioEnFirestore(nombreCalendario, materias);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¡Calendario guardado!'),
          content: Text('El calendario "$nombreCalendario" ha sido creado exitosamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor ingresa un nombre para el calendario')),
      );
    }
  }

  void _generarNuevoCalendario() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SeleccionTipoPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendario = obtenerCalendario();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Calendario'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horario', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              DataTable(
                columns: [
                  DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                  ...diasSemana.map((dia) =>
                    DataColumn(label: Text(dia, style: TextStyle(fontWeight: FontWeight.bold)))),
                ],
                rows: List.generate(horas.length - 1, (horaIndex) {
                  final horaInicio = horas[horaIndex];
                  final horaFin = horas[horaIndex + 1];
                  final rango = '$horaInicio - $horaFin';

                  return DataRow(cells: [
                    DataCell(Text(rango, style: TextStyle(fontWeight: FontWeight.bold))),
                    ...List.generate(diasSemana.length, (diaIndex) {
                      final materia = calendario[diaIndex][horaIndex];
                      if (materia == null) return DataCell(SizedBox());

                      return DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 60),
                          child: Container(
                            padding: EdgeInsets.all(8),
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
                                    '${materia.nombre} (${materia.curso})',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 14, color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                        onPressed: () => widget.onEliminar?.call(materia),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ]);
                }),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Guardar Calendario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    ),
                    onPressed: _guardarCalendario,
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Generar Nuevo Calendario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    ),
                    onPressed: _generarNuevoCalendario,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
