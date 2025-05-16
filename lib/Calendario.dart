class Calendario {
  final String tipo; // "profesor" o "estudiante"
  final List<List<String?>> datos; // Cada celda es una materia o clase

  Calendario({required this.tipo, required this.datos});
}