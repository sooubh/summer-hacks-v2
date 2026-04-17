import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.gradient,
    this.trailing,
    super.key,
  });

  final String label;
  final String value;
  final List<Color> gradient;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: gradient),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
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
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
