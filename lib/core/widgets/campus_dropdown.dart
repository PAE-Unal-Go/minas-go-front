import 'package:flutter/material.dart';

import '../../features/map/domain/entities/campus.dart';
import '../theme/app_design_system.dart';

/// Small pill that lets the user pick a campus. Designed to sit on the dark
/// primary background (home header and map app bar).
class CampusDropdown extends StatelessWidget {
  /// Campus keys as stored in `puntos_de_interes.campus`.
  final List<String> campuses;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const CampusDropdown({
    super.key,
    required this.campuses,
    required this.selected,
    required this.onChanged,
  });

  static const _allLabel = 'Todos los campus';

  @override
  Widget build(BuildContext context) {
    if (campuses.length < 2) return const SizedBox.shrink();

    final label = selected == null ? _allLabel : Campus.humanNombre(selected!);

    return PopupMenuButton<_Choice>(
      tooltip: 'Cambiar campus',
      offset: const Offset(0, 44),
      color: AppColors.surface,
      elevation: 8,
      shadowColor: const Color(0x330F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      onSelected: (choice) => onChanged(choice.key),
      itemBuilder: (_) => [
        _item(const _Choice(null), _allLabel, selected == null),
        for (final key in campuses)
          _item(_Choice(key), Campus.humanNombre(key), key == selected),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 16,
              color: AppColors.secondaryLight,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTypography.fontSizeXs + 1,
                  fontWeight: AppTypography.weightSemiBold,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_Choice> _item(_Choice choice, String text, bool isSelected) {
    return PopupMenuItem<_Choice>(
      value: choice,
      child: Row(
        children: [
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isSelected ? AppColors.secondaryDark : AppColors.disabled,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.fontSizeSm,
              fontWeight: isSelected
                  ? AppTypography.weightBold
                  : AppTypography.weightMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps the nullable campus key so "all campuses" can be a menu value.
class _Choice {
  final String? key;
  const _Choice(this.key);
}
