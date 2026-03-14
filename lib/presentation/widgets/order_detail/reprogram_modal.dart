import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ReprogramModal extends StatefulWidget {
  const ReprogramModal({Key? key}) : super(key: key);

  @override
  State<ReprogramModal> createState() => _ReprogramModalState();
}

class _ReprogramModalState extends State<ReprogramModal> {
  DateTime? _selectedDate;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    // Inicializar formatos de fecha para locale 'es'
    initializeDateFormatting('es').then((_) {
      if (mounted) setState(() {});
    }).catchError((e) {
      // Si falla la inicialización, no evitará la selección de fecha; usar formato por defecto
      // Loguear en consola para depuración
      // ignore: avoid_print
      print('Warning: initializeDateFormatting failed: $e');
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEEE, d MMMM yyyy', 'es');
    final selectedText = _selectedDate == null ? 'No se seleccionó fecha' : df.format(_selectedDate!);
    const primaryColor = Color(0xFF374151); // Gris elegante - opción C

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text('Reprogramar orden',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            )),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date card
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.calendar_today, color: primaryColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha seleccionada', style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(selectedText,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    )),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _pickDate,
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        child: const Text('Cambiar', style: TextStyle(color: primaryColor, fontSize: 12)),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Comment
              TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: null,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Comentario (opcional)',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text('Cancelar', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedDate == null
                        ? null
                        : () => Navigator.of(context).pop({
                              'date': _selectedDate!.toIso8601String(),
                              'comment': _commentController.text,
                            }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text('Reprogramar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
