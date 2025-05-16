import 'package:flutter/material.dart';
import 'EstudianteMateria.dart';
import 'horario_table_page.dart';
import '../home_screen.dart';
import '../calguardados.dart';
import '../favoritos_page.dart';

class HorarioEstudiantePage extends StatefulWidget {
  @override
  _HorarioEstudiantePageState createState() => _HorarioEstudiantePageState();
}

class _HorarioEstudiantePageState extends State<HorarioEstudiantePage> {
  final _nombreController = TextEditingController();
  final _cursoController = TextEditingController();
  final _aulaController = TextEditingController();
  final _profesorController = TextEditingController();

  String? _diaSeleccionado;
  String? _horaInicioSeleccionada;
  String? _horaFinSeleccionada;
  String? _tipoClaseSeleccionado;

  List<MateriaEstudiante> materias = [];
  final List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<String> horasValidas = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00'
  ];
  final List<String> tiposClase = ['Teórica', 'Práctica', 'Examen', 'Laboratorio'];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InicioPage()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CalendariosGuardadosPage()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FavoritosPage()));
        break;
    }
  }

  void _agregarOModificarMateria() {
    final nombre = _nombreController.text.trim();
    final curso = _cursoController.text.trim();
    final aula = _aulaController.text.trim();
    final profesor = _profesorController.text.trim();
    final dia = _diaSeleccionado;
    final horaInicio = _horaInicioSeleccionada;
    final horaFin = _horaFinSeleccionada;
    final tipoClase = _tipoClaseSeleccionado;

    if ([nombre, curso, aula, profesor, dia, horaInicio, horaFin, tipoClase].any((e) => e == null || e.isEmpty)) {
      _mostrarAlerta('Completa todos los campos');
      return;
    }

    int inicioIndex = horasValidas.indexOf(horaInicio!);
    int finIndex = horasValidas.indexOf(horaFin!);

    if (inicioIndex >= finIndex) {
      _mostrarAlerta('Hora fin debe ser mayor a inicio');
      return;
    }

    for (var materia in materias) {
      if (materia.dia == dia) {
        int materiaInicioIndex = horasValidas.indexOf(materia.horaInicio);
        int materiaFinIndex = horasValidas.indexOf(materia.horaFin);
        if (inicioIndex < materiaFinIndex && finIndex > materiaInicioIndex) {
          _mostrarAlerta('El horario se solapa con una materia existente');
          return;
        }
      }
    }

    final nuevaMateria = MateriaEstudiante(
      nombre: nombre,
      curso: curso,
      dia: dia!,
      horaInicio: horaInicio,
      horaFin: horaFin,
      tipoClase: tipoClase!,
      aula: aula,
      profesor: profesor,
    );

    setState(() => materias.add(nuevaMateria));
    _mostrarAlerta('Materia guardada');
    _limpiarCampos();
  }

  void _editarMateria(MateriaEstudiante materia) {
    setState(() {
      _nombreController.text = materia.nombre;
      _cursoController.text = materia.curso;
      _aulaController.text = materia.aula;
      _profesorController.text = materia.profesor;
      _diaSeleccionado = materia.dia;
      _horaInicioSeleccionada = materia.horaInicio;
      _horaFinSeleccionada = materia.horaFin;
      _tipoClaseSeleccionado = materia.tipoClase;
    });
  }

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(mensaje),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  }

  void _limpiarCampos() {
    _nombreController.clear();
    _cursoController.clear();
    _aulaController.clear();
    _profesorController.clear();
    _diaSeleccionado = null;
    _horaInicioSeleccionada = null;
    _horaFinSeleccionada = null;
    _tipoClaseSeleccionado = null;
  }

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
        title: Text('Crear Horario Estudiante'),
        backgroundColor: Colors.blue.shade700,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Vista'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          children: [
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: InputDecoration(labelText: 'Materia', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _cursoController,
                      decoration: InputDecoration(labelText: 'Curso', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _aulaController,
                      decoration: InputDecoration(labelText: 'Aula', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _profesorController,
                      decoration: InputDecoration(labelText: 'Profesor', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _tipoClaseSeleccionado,
                      decoration: InputDecoration(labelText: 'Tipo de clase', border: OutlineInputBorder()),
                      items: tiposClase.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _tipoClaseSeleccionado = v),
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
                'Agregar Materia',
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
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.table_chart, color: Colors.white),
              label: Text(
                'Ver Horario',
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
    );
  }
}
