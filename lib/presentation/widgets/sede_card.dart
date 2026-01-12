import 'package:flutter/material.dart';

class SedeCard extends StatelessWidget {
  final String nombre;
  final String direccion;
  final String? turno;
  final int ordenesAsignadas;
  final bool seleccionada;
  final VoidCallback onTap;
  final VoidCallback onVerDetalle;

  const SedeCard({
    super.key,
    required this.nombre,
    required this.direccion,
    this.turno,
    required this.ordenesAsignadas,
    required this.seleccionada,
    required this.onTap,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: seleccionada ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.house_outlined,
                            size: 25,
                            color: seleccionada ? const Color(0xFF2563EB) : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          direccion,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      if (turno != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            'Turno: $turno',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (seleccionada)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Seleccionada',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$ordenesAsignadas órdenes\nasignadas',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '$ordenesAsignadas órdenes\nasignadas',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            if (seleccionada) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onVerDetalle,
                  child: const Text(
                    'Ver detalle',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
