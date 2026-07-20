import 'package:flutter/material.dart';
import '../../domain/entities/categoria.dart';
import '../../../../core/theme/app_design_system.dart';

/// AppBar dropdown to filter map markers by [Categoria].
class CategoryDropdown extends StatelessWidget {
  final String? selectedKey;
  final List<Categoria> categorias;
  final ValueChanged<String?> onChanged;

  const CategoryDropdown({
    super.key,
    required this.selectedKey,
    required this.categorias,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(value: null, child: Text('Todas')),
      ...categorias.map(
        (c) => DropdownMenuItem(value: c.key, child: Text(c.nombre)),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedKey,
          dropdownColor: AppColors.primaryMain,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          iconEnabledColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
