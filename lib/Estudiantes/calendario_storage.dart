class CalendarioStorage {
  // Lista para almacenar los calendarios junto con su nombre
  static final List<Map<String, dynamic>> calendariosGuardados = [];

  // Guardar un nuevo calendario con nombre
  static void guardar(List<List?> calendario, String nombreCalendario) {
    calendariosGuardados.add({
      'nombre': nombreCalendario,
      'calendario': calendario,
      'fuente': 'estudiantes', // <-- necesario para distinguirlos luego
    });
  }

  // Obtener todos los calendarios guardados
  static List<Map<String, dynamic>> obtenerTodos() {
    return List<Map<String, dynamic>>.from(calendariosGuardados);
  }

  // Eliminar calendario por nombre
  static void eliminarPorNombre(String nombreCalendario) {
    calendariosGuardados.removeWhere((calendario) => calendario['nombre'] == nombreCalendario);
  }
}
