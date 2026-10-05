import 'package:flutter/material.dart';

import '../theme/app_design_system.dart';

/// Five-star input used to rate an unlocked point. Saves through [onRate] and
/// reverts the stars when saving fails.
class PoiRatingInput extends StatefulWidget {
  final int? rating;
  final Future<void> Function(int rating) onRate;
  final bool dark;

  const PoiRatingInput({
    super.key,
    required this.rating,
    required this.onRate,
    this.dark = false,
  });

  @override
  State<PoiRatingInput> createState() => _PoiRatingInputState();
}

class _PoiRatingInputState extends State<PoiRatingInput> {
  int? _value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = widget.rating;
  }

  @override
  void didUpdateWidget(PoiRatingInput old) {
    super.didUpdateWidget(old);
    if (old.rating != widget.rating && !_saving) _value = widget.rating;
  }

  Future<void> _select(int stars) async {
    if (_saving || stars == _value) return;
    final previous = _value;
    setState(() {
      _value = stars;
      _saving = true;
    });
    try {
      await widget.onRate(stars);
    } catch (_) {
      if (!mounted) return;
      setState(() => _value = previous);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('No se pudo guardar tu calificación')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.dark ? Colors.white70 : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _value == null
              ? '¿Qué tal este lugar? Califícalo'
              : 'Tu calificación',
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final star = i + 1;
            final filled = _value != null && star <= _value!;
            return GestureDetector(
              key: ValueKey('rate-star-$star'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _select(star),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.warning,
                  size: 32,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
