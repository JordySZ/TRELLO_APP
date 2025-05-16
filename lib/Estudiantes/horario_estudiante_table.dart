import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'EstudianteMateria.dart';
import '../../seleccion_tipo_page.dart';
import '../calguardados.dart';
import '../../favoritos_page.dart';

class HorarioTable extends StatefulWidget {
  final List<MateriaEstudiante> materias;
  final Function(MateriaEstudiante)? onEliminar;
  final bool mostrarAcciones;

  HorarioTable({
    required this.materias,
    this.onEliminar,
    required this.mostrarAcciones,
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

  List<List<MateriaEstudiante?>> obtenerCalendario() {
    List<List<MateriaEstudiante?>> calendario = List.generate(5, (_) => List.filled(horas.length, null));

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
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SeleccionTipoPage()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CalendariosGuardadosPage()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FavoritosPage()));
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
              onPressed: () => Navigator.of(context).pop(controlador.text),
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

  Future<void> guardarCalendarioEnFirestore(String nombre, List<MateriaEstudiante> materias) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');
      final uid = user.uid;

      final materiasData = materias.map((m) => {
        'nombre': m.nombre,
        'curso': m.curso,
        'dia': m.dia,
        'horaInicio': m.horaInicio,
        'horaFin': m.horaFin,
        'aula': m.aula,
        'profesor': m.profesor,
        'tipoClase': m.tipoClase,
      }).toList();

      await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('calendarios')
        .add({
          'nombre': nombre,
          'materias': materiasData,
          'tipo': 'Estudiante',
          'fecha': FieldValue.serverTimestamp(),
        });

      print('✅ Calendario guardado correctamente dentro del documento del usuario.');
    } catch (e) {
      print('❌ Error al guardar en Firestore: $e');
      rethrow;
    }
  }

  void _guardarCalendario() async {
    final materias = widget.materias;
    String? nombreCalendario = await _mostrarCuadroTexto(context);

    if (nombreCalendario != null && nombreCalendario.isNotEmpty) {
      try {
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el calendario. Intente de nuevo.')),
        );
      }
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horario Estudiantil', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...diasSemana.map((dia) => DataColumn(label: Text(dia, style: TextStyle(fontWeight: FontWeight.bold)))),
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
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${materia.nombre} (${materia.curso})',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                                  Text('Tipo: ${materia.tipoClase}', style: TextStyle(fontSize: 11)),
                                  Text('Aula: ${materia.aula}', style: TextStyle(fontSize: 11)),
                                  Text('Prof: ${materia.profesor}', style: TextStyle(fontSize: 11)),
                                  if (widget.mostrarAcciones)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 16, color: Colors.red),
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
                        );
                      }),
                    ]);
                  }),
                ),
              ),
              const SizedBox(height: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.save, size: 20),
                    label: Text('Guardar Calendario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _guardarCalendario,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh, size: 20),
                    label: Text('Nuevo Calendario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
