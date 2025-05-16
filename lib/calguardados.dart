import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'favoritosProvider.dart';
import 'home_screen.dart';
import 'favoritos_page.dart';

// Importamos con alias para evitar conflictos de nombres
import 'Detalles/DetalleCalendarioPage.dart'  as estDetalle;   // Para profesor
import 'DetalleCalendarioPage.dart'   as profDetalle;          // Para estudiante
import 'configuraciones/EditarCalendarioPage.dart';

import 'Profesores/calendario_storage.dart' as prof;
import 'Estudiantes/calendario_storage.dart' as est;

class CalendariosGuardadosPage extends StatefulWidget {
  @override
  _CalendariosGuardadosPageState createState() => _CalendariosGuardadosPageState();
}

class _CalendariosGuardadosPageState extends State<CalendariosGuardadosPage> {
  int _selectedIndex = 1;
  List<Map<String, dynamic>> _todosCalendarios = [];

  @override
  void initState() {
    super.initState();
    _cargarTodosLosCalendarios();
  }

  Future<void> _cargarTodosLosCalendarios() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Usuario no autenticado");
      return;
    }
    final uid = user.uid;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('calendarios')
          .orderBy('fecha', descending: true)
          .get();

      final calendarios = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['fuente'] = 'firestore_usuario';
        data['tipo'] = (data['tipo'] ?? 'estudiante').toString().toLowerCase();
        data['nombre'] = data['nombre'] ?? 'Sin nombre';
        return data;
      }).toList();

      setState(() {
        _todosCalendarios = calendarios;
      });
    } catch (e) {
      print("Error al cargar calendarios del usuario: $e");
    }
  }

  Future<void> eliminarCalendarioFirestorePorId(String id, String fuente) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (fuente == 'firestore_usuario') {
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('calendarios')
            .doc(id)
            .delete();
      } catch (e) {
        print('Error al eliminar calendario: $e');
      }
    }
    // Puedes agregar más lógica si manejas otras fuentes.
    await _cargarTodosLosCalendarios();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InicioPage()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FavoritosPage()));
        break;
    }
  }

  Future<void> _mostrarDetalleCalendario(Map<String, dynamic> calendario) async {
    final tipo = (calendario['tipo'] ?? 'estudiante').toString().toLowerCase();
    final docId = calendario['id'] ?? '';

    Widget destino;
    if (tipo == 'profesor') {
      destino = profDetalle.DetalleCalendarioPage(calendario: calendario, calendarioDocId: docId);
    } else {
      destino = estDetalle.DetalleCalendarioEstudiantePage(calendario: calendario);
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
    await _cargarTodosLosCalendarios();
  }

  Future<void> _mostrarEditarCalendario(Map<String, dynamic> calendario) async {
    final docId = calendario['id'] ?? '';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarCalendarioPage(calendario: calendario, docId: docId),
      ),
    );
    await _cargarTodosLosCalendarios();
  }

  @override
  Widget build(BuildContext context) {
    final favoritosProvider = Provider.of<FavoritosProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendarios Guardados'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
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
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Calendarios'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: _todosCalendarios.isEmpty
            ? Center(child: Text('No hay calendarios guardados.'))
            : ListView.builder(
                itemCount: _todosCalendarios.length,
                itemBuilder: (context, index) {
                  final calendario = _todosCalendarios[index];
                  final nombre = calendario['nombre'] ?? 'Sin nombre';
                  final id = calendario['id'] ?? '';
                  final fuente = calendario['fuente'] ?? '';
                  final esFavorito = favoritosProvider.favoritos.any((fav) => fav['id'] == id);

                  return Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade700,
                        child: Icon(Icons.calendar_today, color: Colors.white),
                      ),
                      title: Text(nombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          )),
                      subtitle: Text('Ver detalles', style: TextStyle(color: Colors.blue.shade400)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(esFavorito ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                esFavorito
                                    ? favoritosProvider.quitarFavorito(calendario)
                                    : favoritosProvider.agregarFavorito(calendario);
                              });
                            },
                          ),
                          // Icono de editar eliminado según tu pedido
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              if (esFavorito) {
                                await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text('No se puede eliminar'),
                                    content: Text(
                                        'Este calendario está marcado como favorito.\nDesmárcalo primero para eliminarlo.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: Text('Entendido')),
                                    ],
                                  ),
                                );
                                return;
                              }

                              final confirmar = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Confirmar eliminación'),
                                  content: Text('¿Eliminar calendario "$nombre"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Eliminar')),
                                  ],
                                ),
                              );

                              if (confirmar != true) return;

                              if (fuente.toString().startsWith('firestore')) {
                                await eliminarCalendarioFirestorePorId(id, fuente);
                              } else if (fuente == 'profesores') {
                                prof.CalendarioStorage.eliminarPorNombre(nombre);
                              } else if (fuente == 'estudiantes') {
                                est.CalendarioStorage.eliminarPorNombre(nombre);
                              }

                              setState(() {
                                _todosCalendarios.removeWhere((c) => c['id'] == id);
                              });
                            },
                            tooltip: 'Eliminar',
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.blue.shade700),
                        ],
                      ),
                      onTap: () => _mostrarDetalleCalendario(calendario),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
