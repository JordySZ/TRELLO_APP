import 'package:flutter/material.dart';
import 'materia.dart';
import 'horario_table_page.dart';
import '../home_screen.dart'; // Página principal
import '../calguardados.dart'; // Calendarios guardados
import '../favoritos_page.dart'; // Página de favoritos

class HorarioPage extends StatefulWidget {
  @override
  _HorariooPageState createState() => _HorariooPageState();
}

class _HorariooPageState extends State<HorarioPage> {
  
  final _nombreController = TextEditingController();
  final _cursoController = TextEditingController();
  String? _diaSeleccionado;
  String? _horaInicioSeleccionada;
  String? _horaFinSeleccionada;
  List<List<List<Materia?>>> calendarios = [];
  List<List?> favoritos = []; // Lista de favoritos
  final List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<String> horasValidas = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00'
  ];

  List<Materia> materias = [];
  int _selectedIndex = 0; // Índice seleccionado del BottomNavigationBar

  // Función para navegar entre páginas del BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Redirige a las diferentes páginas dependiendo del índice seleccionado
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => InicioPage()), // Página principal
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CalendariosGuardadosPage(), // Página de calendarios guardados
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FavoritosPage()), // Página de favoritos
        );
        break;
      default:
        break;
    }
  }

  // Función para agregar o modificar una materia
  void _agregarOModificarMateria() {
    final nombre = _nombreController.text.trim();
    final curso = _cursoController.text.trim();
    final dia = _diaSeleccionado;
    final horaInicio = _horaInicioSeleccionada;
    final horaFin = _horaFinSeleccionada;

    // Verificar si hay algún campo vacío
    if ([nombre, curso, dia, horaInicio, horaFin].any((e) => e == null || e.isEmpty)) {
      _mostrarAlerta('Completa todos los campos');
      return;
    }

    int inicioIndex = horasValidas.indexOf(horaInicio!);
    int finIndex = horasValidas.indexOf(horaFin!);

    // Verificar si la hora de inicio es menor que la de fin
    if (inicioIndex >= finIndex) {
      _mostrarAlerta('Hora fin debe ser mayor a inicio');
      return;
    }

    // Verificar si el nuevo horario se solapa con alguno ya existente
    for (var materia in materias) {
      if (materia.dia == dia) {
        int materiaInicioIndex = horasValidas.indexOf(materia.horaInicio);
        int materiaFinIndex = horasValidas.indexOf(materia.horaFin);

        // Verificar si los horarios se solapan
        if ((inicioIndex < materiaFinIndex && finIndex > materiaInicioIndex)) {
          _mostrarAlerta('El horario se solapa con una materia existente');
          return;
        }
      }
    }

    // Crear la nueva materia
    final nuevaMateria = Materia(
      nombre: nombre,
      dia: dia!,
      horaInicio: horaInicio,
      horaFin: horaFin!,
      curso: curso,
    );

    setState(() {
      // Eliminar la materia existente si ya existe con el mismo nombre, curso, día y hora
      materias.removeWhere((m) =>
        m.nombre == nombre && m.dia == dia && m.horaInicio == horaInicio && m.curso == curso);
      materias.add(nuevaMateria);
    });

    _mostrarAlerta('Materia guardada');
    _limpiarCampos();
  }

  // Función para editar una materia
  void _editarMateria(Materia materia) {
    setState(() {
      _nombreController.text = materia.nombre;
      _cursoController.text = materia.curso;
      _diaSeleccionado = materia.dia;
      _horaInicioSeleccionada = materia.horaInicio;
      _horaFinSeleccionada = materia.horaFin;
    });
  }

  // Mostrar una alerta
  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(mensaje),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  }

  // Limpiar los campos del formulario
  void _limpiarCampos() {
    _nombreController.clear();
    _cursoController.clear();
    _diaSeleccionado = null;
    _horaInicioSeleccionada = null;
    _horaFinSeleccionada = null;
  }

  // Ver el horario en una tabla
  void _verHorario() {
    if (materias.isEmpty) {
      _mostrarAlerta('No hay materias');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HorarioTablePage(
          materias: materias,
          onEditar: _editarMateria,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Horario'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped, // Llamamos la función para cambiar la página cuando un ítem es tocado
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Vista en cuadrícula'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
        ],
      ),
      body: Stack(
        children: [
          // Fondo azul doblado
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              height: 250,
              color: Colors.blue.shade700,
            ),
          ),
          // Contenedor con imagen circular y título
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(height: 10),
                Text(
                  'Calendario Académico',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                ClipOval(
                  child: Container(
                    height: 120,
                    width: 120,
                    child: Image.asset(
                      'images/calendario.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Formulario principal
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 270, 16, 100),
            child: Column(
              children: [
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Materia',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _cursoController,
                          decoration: InputDecoration(
                            labelText: 'Curso',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _diaSeleccionado,
                          decoration: InputDecoration(labelText: 'Día', border: OutlineInputBorder()),
                          items: diasSemana.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setState(() => _diaSeleccionado = v),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _horaInicioSeleccionada,
                          decoration: InputDecoration(labelText: 'Hora inicio', border: OutlineInputBorder()),
                          items: horasValidas.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                          onChanged: (v) => setState(() => _horaInicioSeleccionada = v),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _horaFinSeleccionada,
                          decoration: InputDecoration(labelText: 'Hora fin', border: OutlineInputBorder()),
                          items: horasValidas.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                          onChanged: (v) => setState(() => _horaFinSeleccionada = v),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Agregar/Guardar Materia',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 6,
                    shadowColor: Colors.blue.shade300,
                  ),
                  onPressed: _agregarOModificarMateria,
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.table_chart, color: Colors.white),
                  label: Text(
                    'Crear Horario',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 6,
                    shadowColor: Colors.green.shade300,
                  ),
                  onPressed: _verHorario,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Clipper personalizado
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, 0);
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height - 10);
    path.quadraticBezierTo(size.width * 3 / 4, size.height - 20, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
