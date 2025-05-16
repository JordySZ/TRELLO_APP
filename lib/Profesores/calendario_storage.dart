class CalendarioStorage {
  static final List<Map<String, dynamic>> calendariosGuardados = [];

  static void guardar(List<List?> calendario, String nombreCalendario) {
    calendariosGuardados.add({
      'nombre': nombreCalendario,
      'calendario': calendario,
      'fuente': 'profesores', // o 'estudiantes' según corresponda
    });
  }

  static List<Map<String, dynamic>> obtenerTodos() {
    return calendariosGuardados;
  }

  // ESTE MÉTODO HAY QUE AGREGARLO PARA ELIMINAR POR NOMBRE
  static void eliminarPorNombre(String nombre) {
    calendariosGuardados.removeWhere((cal) => cal['nombre'] == nombre);
  }
}
