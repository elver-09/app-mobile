import 'package:flutter/material.dart';

class OrdersFilterSwitch extends StatefulWidget {
  final ValueChanged<bool> onFilterChanged;

  const OrdersFilterSwitch({
    super.key,
    required this.onFilterChanged,
  });

  @override
  State<OrdersFilterSwitch> createState() => _OrdersFilterSwitchState();
}

class _OrdersFilterSwitchState extends State<OrdersFilterSwitch> {
  bool _showOnlyActive = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: const Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showOnlyActive 
                      ? 'En Transporte y En curso'
                      : 'Todas las órdenes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _showOnlyActive,
            onChanged: (value) {
              setState(() {
                _showOnlyActive = value;
              });
              widget.onFilterChanged(value);
            },
            activeColor: const Color(0xFF2563EB),
            inactiveThumbColor: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}
