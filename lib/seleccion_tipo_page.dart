import 'package:flutter/material.dart';
import 'Profesores/horario_page.dart';
import 'home_screen.dart';
import 'Estudiantes/horario_estudiante_page.dart';
import 'calguardados.dart'; // Calendarios guardados
import 'favoritos_page.dart';
class SeleccionTipoPage extends StatefulWidget {
  @override
  _SeleccionTipoPageState createState() => _SeleccionTipoPageState();
}

class _SeleccionTipoPageState extends State<SeleccionTipoPage> {
  int _selectedIndex = 0; // Estado para el índice seleccionado del BottomNavigationBar

  List<List?> favoritos = [];
  // Función que maneja el cambio de página al tocar un ítem del BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Redirige a las diferentes páginas dependiendo del índice seleccionado
     switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => InicioPage()), // Página de inicio
        );
        break;
      case 1:
        // Navega a la página CalendariosGuardadosPage pasando los calendarios
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CalendariosGuardadosPage(), // Pasamos los calendarios
          ),
        );
        break;
      case 2:
        // Aquí iría la navegación a la página de favoritos, por ahora está comentado
       Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => FavoritosPage()), // Solo navegas a la página de favoritos
);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
  
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Text(
              '¿Para quién es el horario?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona una opción para continuar.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Contenedor con opciones
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildOptionTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'Profesor',
                    subtitle: 'Crea un horario para docentes.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HorarioPage()),
                      );
                    },
                  ),
                  Divider(height: 32),
                  _buildOptionTile(
                    context,
                    icon: Icons.school_outlined,
                    title: 'Estudiante',
                    subtitle: 'Crea un horario para alumnos.',
                    onTap: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HorarioEstudiantePage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Podrás modificar los horarios más adelante.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
