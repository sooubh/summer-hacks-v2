import 'package:flutter/material.dart';

class AlertsSheet extends StatelessWidget {
  const AlertsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Alerts & Reminders', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: const [
                _AlertTile(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  title: "Your Burn Rate is Heating Up!",
                  subtitle: "You are 20% above your weekly average. Tap to review your recent Swiggy transactions.",
                  time: '2 hours ago',
                ),
                _AlertTile(
                  icon: Icons.emoji_events,
                  iconColor: Colors.amber,
                  title: "You're so close to Bronze Saver!",
                  subtitle: "Save just ₹500 more this week to rank up and unlock your next badge.",
                  time: '5 hours ago',
                ),
                _AlertTile(
                  icon: Icons.trending_up,
                  iconColor: Colors.green,
                  title: "Smart SIP Opportunity",
                  subtitle: "Your Safe to Spend balance is looking very healthy. Ask FinMate AI how to sweep ₹2,000 into an Index Fund.",
                  time: '1 day ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _AlertTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.2),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
      onTap: () {
        Navigator.pop(context);
        // We could redirect securely if we wanted here via AppRouter.
      },
    );
  }
}