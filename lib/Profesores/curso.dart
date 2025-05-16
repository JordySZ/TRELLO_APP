import 'materia.dart';

class Curso {
  final String nombre;
  final List<Materia> materias;

  Curso({required this.nombre, this.materias = const []});
}
