import 'dart:async'; // <--- Importante para el temporizador
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'board_models.dart';

class CardDetailsDialog extends StatefulWidget {
  final BoardCard card;
  final DocumentReference cardRef;

  const CardDetailsDialog({
    super.key, 
    required this.card, 
    required this.cardRef
  });

  @override
  State<CardDetailsDialog> createState() => _CardDetailsDialogState();
}

class _CardDetailsDialogState extends State<CardDetailsDialog> {
  late String _currentStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  
  late List<Map<String, dynamic>> _subtasks;
  final TextEditingController _subtaskController = TextEditingController();

  // --- VARIABLES PARA AUTOGUARDADO ---
  late TextEditingController _descriptionController;
  Timer? _debounce; // El temporizador
  String _saveStatus = "Guardado"; // Texto de estado
  Color _statusColor = Colors.green; // Color del estado

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.card.status;
    _startDate = widget.card.startDate;
    _endDate = widget.card.endDate;
    _subtasks = List.from(widget.card.subtasks);
    
    _descriptionController = TextEditingController(text: widget.card.description);
  }

  @override
  void dispose() {
    // Si el usuario cierra el diálogo mientras el temporizador corre,
    // guardamos inmediatamente para no perder datos.
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _saveDescriptionNow();
    }
    
    _subtaskController.dispose();
    _descriptionController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _updateCardField(String field, dynamic value) async {
    // Actualización optimista (UI primero)
    if (mounted) {
      setState(() {
        if (field == 'status') _currentStatus = value;
        if (field == 'startDate') _startDate = value;
        if (field == 'endDate') _endDate = value;
        if (field == 'subtasks') _subtasks = value;
      });
    }
    // Actualización en Firebase
    await widget.cardRef.update({field: value});
  }

  // --- LÓGICA DE AUTOGUARDADO INTELIGENTE ---
  void _onDescriptionChanged(String text) {
    // 1. Cambiamos el estado a "Escribiendo..."
    if (_saveStatus != "Escribiendo...") {
      setState(() {
        _saveStatus = "Escribiendo...";
        _statusColor = Colors.orange;
      });
    }

    // 2. Cancelamos el temporizador anterior si existe
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 3. Iniciamos un nuevo temporizador de 1 segundo
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _saveDescriptionNow();
    });
  }

  void _saveDescriptionNow() {
    final text = _descriptionController.text.trim();
    // Guardamos en Firebase
    widget.cardRef.update({'description': text}).then((_) {
      if (mounted) {
        setState(() {
          _saveStatus = "Guardado en la nube";
          _statusColor = Colors.green;
        });
        
        // Opcional: Ocultar el mensaje de "Guardado" después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
           if (mounted && _saveStatus == "Guardado en la nube") {
             setState(() => _saveStatus = "");
           }
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _saveStatus = "Error al guardar";
          _statusColor = Colors.red;
        });
      }
    });
  }
  // ------------------------------------------

  // (Resto de funciones auxiliares igual que antes)
  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    final newSubtask = {'title': text, 'done': false};
    final updatedList = [..._subtasks, newSubtask];
    _updateCardField('subtasks', updatedList);
    _subtaskController.clear();
  }

  void _toggleSubtask(int index, bool? value) {
    final updatedList = List<Map<String, dynamic>>.from(_subtasks);
    updatedList[index]['done'] = value ?? false;
    _updateCardField('subtasks', updatedList);
  }

  void _deleteSubtask(int index) {
    final updatedList = List<Map<String, dynamic>>.from(_subtasks);
    updatedList.removeAt(index);
    _updateCardField('subtasks', updatedList);
  }

  double _calculateProgress() {
    if (_subtasks.isEmpty) return 0.0;
    final doneCount = _subtasks.where((s) => s['done'] == true).length;
    return doneCount / _subtasks.length;
  }

  Future<void> _pickDate(bool isStartDate) async {
    final initialDate = isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _updateCardField(isStartDate ? 'startDate' : 'endDate', picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '---';
    return "${date.day}/${date.month}/${date.year}";
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hecho': return Colors.green.shade100;
      case 'por_hacer': return Colors.blue.shade100;
      case 'pendiente': default: return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(24),
      title: Text(widget.card.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. ESTADO
              const Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: _getStatusColor(_currentStatus), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currentStatus,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'pendiente', child: Text('⏳ Pendiente')),
                      DropdownMenuItem(value: 'por_hacer', child: Text('🔨 Por hacer')),
                      DropdownMenuItem(value: 'hecho', child: Text('✅ Hecho')),
                    ],
                    onChanged: (val) => _updateCardField('status', val),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // 2. DESCRIPCIÓN (MEJORADA)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  // Indicador de estado (Guardando... / Guardado)
                  if (_saveStatus.isNotEmpty)
                    Text(
                      _saveStatus,
                      style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4, // Un poco más alto para que se vea mejor
                minLines: 2,
                onChanged: _onDescriptionChanged, // <--- AQUÍ OCURRE LA MAGIA
                decoration: InputDecoration(
                  hintText: 'Añade más detalles a esta tarea...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. FECHAS
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Inicio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                          child: Row(children: [const Icon(Icons.calendar_today, size: 14), const SizedBox(width: 4), Text(_formatDate(_startDate))]),
                        )
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Vencimiento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                          child: Row(children: [const Icon(Icons.event_busy, size: 14), const SizedBox(width: 4), Text(_formatDate(_endDate))]),
                        )
                      ]),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),

              // 4. SUBTAREAS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtareas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("${(_calculateProgress() * 100).toInt()}%", style: const TextStyle(color: Colors.grey)),
                ],
              ),
              if (_subtasks.isNotEmpty)
                LinearProgressIndicator(value: _calculateProgress(), backgroundColor: Colors.grey.shade200, color: Colors.blue),
              
              const SizedBox(height: 10),
              
              ..._subtasks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Checkbox(
                    value: task['done'] ?? false,
                    onChanged: (val) => _toggleSubtask(index, val),
                  ),
                  title: Text(
                    task['title'],
                    style: TextStyle(
                      decoration: (task['done'] ?? false) ? TextDecoration.lineThrough : null,
                      color: (task['done'] ?? false) ? Colors.grey : Colors.black,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                    onPressed: () => _deleteSubtask(index),
                  ),
                );
              }),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: const InputDecoration(hintText: 'Añadir un paso...', isDense: true),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue), onPressed: _addSubtask),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          // Ahora simplemente cerramos, ya que se guarda solo
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}