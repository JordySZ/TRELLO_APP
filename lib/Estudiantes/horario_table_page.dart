import 'package:flutter/material.dart';
import 'EstudianteMateria.dart';
import 'horario_estudiante_table.dart';

class HorarioTablePage extends StatefulWidget {
  final List<MateriaEstudiante> materias;
  final void Function(MateriaEstudiante) onEditar;

  HorarioTablePage({
    required this.materias,
    required this.onEditar,
  });

  @override
  _HorarioTablePageState createState() => _HorarioTablePageState();
}

class _HorarioTablePageState extends State<HorarioTablePage> {
  late List<MateriaEstudiante> _materias;
  bool _mostrarAcciones = false;

  @override
  void initState() {
    super.initState();
    _materias = List.from(widget.materias);
  }

  void _eliminarMateria(MateriaEstudiante materia) {
    setState(() {
      _materias.remove(materia);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horario generado'),
        backgroundColor: Colors.blue,
        // Se eliminó el botón de editar aquí
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: HorarioTable(
          materias: _materias,
          onEliminar: _eliminarMateria,
          mostrarAcciones: _mostrarAcciones, // <- puedes dejarlo en false también si ya no usarás acciones
        ),
      ),
    );
  }
}
