import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';

class ReprogramModal extends StatefulWidget {
  final OdooClient? odooClient;
  final String? token;

  const ReprogramModal({Key? key, this.odooClient, this.token})
    : super(key: key);

  @override
  State<ReprogramModal> createState() => _ReprogramModalState();
}

class _ReprogramModalState extends State<ReprogramModal> {
  DateTime? _selectedDate;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _changeDistrict = false;
  bool _loadingDistricts = false;
  List<Map<String, dynamic>> _districts = [];
  int? _selectedDistrictId;

  List<Map<String, dynamic>> get _filteredDistricts {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _districts
        : _districts.where((district) {
            final name = (district['name'] as String?)?.toLowerCase() ?? '';
            return name.contains(query);
          }).toList();

    // Evitar valores duplicados en el dropdown
    final seenIds = <int>{};
    return filtered.where((district) {
      final id = district['id'] as int?;
      if (id == null || seenIds.contains(id)) {
        return false;
      }
      seenIds.add(id);
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    // Inicializar formatos de fecha para locale 'es'
    initializeDateFormatting('es')
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((e) {
          // Si falla la inicialización, no evitará la selección de fecha; usar formato por defecto
          // Loguear en consola para depuración
          // ignore: avoid_print
          print('Warning: initializeDateFormatting failed: $e');
        });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _searchController.dispose();
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
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _loadDistricts() async {
    if (widget.odooClient == null || widget.token == null) return;
    setState(() => _loadingDistricts = true);
    try {
      final data = await widget.odooClient!.fetchDistricts(
        token: widget.token!,
      );
      setState(() {
        _districts = data;
        // No seleccionar ninguno por defecto
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error cargando distritos: $e');
    } finally {
      setState(() => _loadingDistricts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEEE, d MMMM yyyy', 'es');
    final selectedText = _selectedDate == null
        ? 'No se seleccionó fecha'
        : df.format(_selectedDate!);
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
                    child: Text(
                      'Reprogramar orden',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
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
                        child: const Icon(
                          Icons.calendar_today,
                          color: primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha seleccionada',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedText,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _pickDate,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: const Text(
                          'Cambiar',
                          style: TextStyle(color: primaryColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Switch para cambiar distrito
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '¿Quieres cambiar el distrito ?',
                    style: TextStyle(fontSize: 13),
                  ),
                  Switch(
                    value: _changeDistrict,
                    onChanged: (v) async {
                      setState(() => _changeDistrict = v);
                      if (v) {
                        await _loadDistricts();
                      }
                    },
                  ),
                ],
              ),

              if (_changeDistrict) ...[
                const SizedBox(height: 8),
                _loadingDistricts
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Buscar distrito',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final filteredDistricts = _filteredDistricts;
                              final selectedValue =
                                  filteredDistricts.any(
                                    (d) => d['id'] == _selectedDistrictId,
                                  )
                                  ? _selectedDistrictId
                                  : null;

                              return filteredDistricts.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.25),
                                        ),
                                      ),
                                      child: const Text(
                                        'No se encontraron distritos',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    )
                                  : DropdownButtonFormField<int>(
                                      value: selectedValue,
                                      items: filteredDistricts
                                          .map(
                                            (d) => DropdownMenuItem<int>(
                                              value: d['id'] as int,
                                              child: Text(d['name'] ?? ''),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) => setState(() {
                                        _selectedDistrictId = v;
                                      }),
                                      decoration: InputDecoration(
                                        hintText: 'Selecciona distrito',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    );
                            },
                          ),
                        ],
                      ),
              ],

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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        (_selectedDate == null ||
                            (_changeDistrict && _selectedDistrictId == null))
                        ? null
                        : () => Navigator.of(context).pop({
                            'date': _selectedDate!.toIso8601String(),
                            'comment': _commentController.text,
                            'area_id': _changeDistrict
                                ? _selectedDistrictId
                                : null,
                          }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Reprogramar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
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
