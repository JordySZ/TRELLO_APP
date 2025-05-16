import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'favoritosProvider.dart';
import 'home_screen.dart';
import 'calguardados.dart';

// Importa con alias para evitar conflictos
import 'Detalles/DetalleCalendarioPage.dart' as estDetalle;   // Para estudiante
import 'DetalleCalendarioPage.dart' as profDetalle;           // Para profesor

class FavoritosPage extends StatefulWidget {
  @override
  _FavoritosPageState createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => InicioPage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CalendariosGuardadosPage()),
        );
        break;
      case 2:
        // Ya estamos aquí
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritos = Provider.of<FavoritosProvider>(context).favoritos;

    return Scaffold(
      appBar: AppBar(
        title: Text('Favoritos'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: favoritos.isEmpty
            ? Center(
                child: Text(
                  'No hay calendarios favoritos',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              )
            : ListView.builder(
                itemCount: favoritos.length,
                itemBuilder: (context, index) {
                  final calendario = favoritos[index];
                  final nombre = calendario['nombre'] ?? 'Calendario ${index + 1}';
                  final tipo = (calendario['tipo'] ?? 'estudiante').toString().toLowerCase();
                  final id = calendario['id'] ?? '';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.star, color: Colors.yellow),
                      title: Text(nombre),
                      subtitle: Text('Toca para ver detalles'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        Widget destino;

                        if (tipo == 'profesor') {
                          destino = profDetalle.DetalleCalendarioPage(
                            calendario: calendario,
                            calendarioDocId: id,
                          );
                        } else {
                          destino = estDetalle.DetalleCalendarioEstudiantePage(
                            calendario: calendario,
                          );
                        }

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => destino),
                        );

                        // Si viene el resultado 'eliminado', quitar el favorito
                        if (result == 'eliminado') {
                          Provider.of<FavoritosProvider>(context, listen: false)
                              .quitarFavorito(calendario);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Vista en cuadrícula'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
        ],
      ),
    );
  }
}
