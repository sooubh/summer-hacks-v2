import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/gamification_models.dart';
import 'package:student_fin_os/providers/gamification_providers.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gamificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards & Achievements'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 64),
                    const SizedBox(height: 8),
                    Text(
                      ' FinCoins',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current Rank: ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha:0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(profile.currentRank, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(profile.nextRank, style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: profile.progressToNextRank,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(8),
                            backgroundColor: Colors.grey.withValues(alpha:0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Badges',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final badge = profile.badges[index];
                    return _BadgeCard(badge: badge);
                  },
                  childCount: profile.badges.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final RewardBadge badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: badge.isUnlocked 
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha:0.4) 
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.isUnlocked ? Colors.green.withValues(alpha:0.5) : Colors.grey.withValues(alpha:0.2),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.isUnlocked ? Colors.amber.withValues(alpha:0.2) : Colors.grey.withValues(alpha:0.1),
            ),
            child: Text(
              badge.icon,
              style: TextStyle(
                fontSize: 32,
                color: badge.isUnlocked ? null : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: badge.isUnlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: badge.isUnlocked ? null : Colors.grey,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}