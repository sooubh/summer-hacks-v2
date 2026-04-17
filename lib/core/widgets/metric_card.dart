import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.gradient,
    this.trailing,
    this.suggestionText,
    this.suggestionIcon,
    this.suggestionColor,
    super.key,
  });

  final String label;
  final String value;
  final List<Color> gradient;
  final Widget? trailing;
  final String? suggestionText;
  final IconData? suggestionIcon;
  final Color? suggestionColor;

  @override
  Widget build(BuildContext context) {
    final Color accent = gradient.isEmpty ? Theme.of(context).colorScheme.primary : gradient.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (suggestionText != null) ...[
            const Spacer(),
            Row(
              children: [
                if (suggestionIcon != null) ...[
                  Icon(
                    suggestionIcon,
                    size: 14,
                    color: suggestionColor ?? Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    suggestionText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: suggestionColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
