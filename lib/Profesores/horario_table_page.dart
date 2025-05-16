import 'package:flutter/material.dart';
import 'materia.dart';
import 'horario_table.dart';

class HorarioTablePage extends StatefulWidget {
  final List<Materia> materias;
  final void Function(Materia) onEditar;

  HorarioTablePage({
    required this.materias,
    required this.onEditar,
  });

  @override
  _HorarioTablePageState createState() => _HorarioTablePageState();
}

class _HorarioTablePageState extends State<HorarioTablePage> {
  late List<Materia> _materias;

  @override
  void initState() {
    super.initState();
    _materias = List.from(widget.materias);
  }

  void _eliminarMateria(Materia materia) {
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: HorarioTable(
          materias: _materias,
          onEliminar: _eliminarMateria,
        ),
      ),
    );
  }
}
