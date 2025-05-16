import 'package:flutter/material.dart';


class DetalleCalendarioPage extends StatelessWidget {
  final List<List?> calendario;

  DetalleCalendarioPage({required this.calendario});

  final List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<String> horas = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Calendario'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Hacer scroll si el contenido es demasiado grande
          child: DataTable(
            columnSpacing: 16.0, // Espacio entre columnas
            horizontalMargin: 12.0, // Margen horizontal
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
            dataTextStyle: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            columns: [
              DataColumn(
                label: Text('Hora'),
              ),
              ...diasSemana.map(
                (dia) => DataColumn(
                  label: Text(dia),
                ),
              ),
            ],
            rows: List.generate(horas.length - 1, (horaIndex) {
              final horaInicio = horas[horaIndex];
              final horaFin = horas[horaIndex + 1];
              final rango = '$horaInicio - $horaFin';

              return DataRow(cells: [
                DataCell(
                  Text(rango, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...List.generate(diasSemana.length, (diaIndex) {
                  final materia = calendario[diaIndex]![horaIndex];
                  if (materia == null) return DataCell(SizedBox());

                  return DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${materia.nombre} (${materia.curso})',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
