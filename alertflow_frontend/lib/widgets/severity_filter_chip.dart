import 'package:flutter/material.dart';

class SeverityFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color color;
  final IconData? icon;

  const SeverityFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey[100],
      selectedColor: color,
      checkmarkColor: Colors.white,
      elevation: isSelected ? 4 : 1,
      pressElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : Colors.grey[300]!,
          width: 1,
        ),
      ),
    );
  }
}

class SeverityFilterRow extends StatelessWidget {
  final String selectedSeverity;
  final Function(String) onSeverityChanged;

  const SeverityFilterRow({
    super.key,
    required this.selectedSeverity,
    required this.onSeverityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {
        'label': 'All',
        'value': 'all',
        'color': Colors.grey[600]!,
        'icon': Icons.filter_list
      },
      {
        'label': 'Minor',
        'value': 'minor',
        'color': Colors.blue,
        'icon': Icons.info
      },
      {
        'label': 'Moderate',
        'value': 'moderate',
        'color': Colors.orange,
        'icon': Icons.warning
      },
      {
        'label': 'Major',
        'value': 'major',
        'color': Colors.red,
        'icon': Icons.error
      },
      {
        'label': 'Critical',
        'value': 'critical',
        'color': Colors.purple,
        'icon': Icons.dangerous
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SeverityFilterChip(
                label: filter['label'] as String,
                isSelected: selectedSeverity == filter['value'],
                onSelected: () => onSeverityChanged(filter['value'] as String),
                color: filter['color'] as Color,
                icon: filter['icon'] as IconData?,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
