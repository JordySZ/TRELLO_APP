class MateriaEstudiante {
  final String nombre;
  final String curso;
  final String dia;
  final String horaInicio;
  final String horaFin;
  final String tipoClase; // Reemplazo de 'grupo'
  final String aula;
  final String profesor;

  MateriaEstudiante({
    required this.nombre,
    required this.curso,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.tipoClase,
    required this.aula,
    required this.profesor,
  });
}
