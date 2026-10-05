import 'package:flutter/material.dart';

import '../../features/map/domain/entities/campus.dart';
import '../theme/app_design_system.dart';

/// Campus location picker pill for home header and map app bar.
class CampusDropdown extends StatelessWidget {
  /// Campus group keys (see [Campus.distinct]).
  final List<String> campuses;
  final String? selected;
  final ValueChanged<String?> onChanged;

  /// Stretch the pill to the available width (map header).
  final bool expanded;

  const CampusDropdown({
    super.key,
    required this.campuses,
    required this.selected,
    required this.onChanged,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (campuses.length < 2) return const SizedBox.shrink();

    final effective =
        selected == null ? null : Campus.groupOf(selected!);
    final label = effective == null
        ? Campus.humanNombre(campuses.first)
        : Campus.humanNombre(effective);

    final pill = Container(
      width: expanded ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 16,
            color: AppColors.secondaryLight,
          ),
          const SizedBox(width: 6),
          if (expanded)
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _labelStyle,
              ),
            )
          else
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _labelStyle,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Colors.white,
          ),
        ],
      ),
    );

    final menu = PopupMenuButton<String>(
      tooltip: 'Cambiar campus',
      offset: const Offset(0, 44),
      color: AppColors.surface,
      elevation: 8,
      shadowColor: const Color(0x330F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final key in campuses)
          _item(key, Campus.humanNombre(key), key == effective),
      ],
      child: pill,
    );

    // Expanded needs a bounded width; home keeps intrinsic size.
    if (!expanded) return menu;
    return SizedBox(width: double.infinity, child: menu);
  }

  static const _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: AppTypography.fontSizeXs + 1,
    fontWeight: AppTypography.weightSemiBold,
    height: 1.1,
  );

  PopupMenuItem<String> _item(String key, String text, bool isSelected) {
    return PopupMenuItem<String>(
      value: key,
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
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppTypography.fontSizeSm,
                fontWeight: isSelected
                    ? AppTypography.weightBold
                    : AppTypography.weightMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
