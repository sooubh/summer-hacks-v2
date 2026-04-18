import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/gamification_models.dart';
import 'package:student_fin_os/providers/gamification_providers.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FinRewardProfile profile = ref.watch(gamificationProvider);
    final List<RewardActivity> activities = List<RewardActivity>.from(profile.activities)
      ..sort((RewardActivity a, RewardActivity b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.coinReward.compareTo(a.coinReward);
      });

    final List<RewardBadge> badges = List<RewardBadge>.from(profile.badges)
      ..sort((RewardBadge a, RewardBadge b) {
        if (a.isUnlocked != b.isUnlocked) {
          return a.isUnlocked ? -1 : 1;
        }
        return b.coinReward.compareTo(a.coinReward);
      });

    final int completedActivities =
        activities.where((RewardActivity item) => item.isCompleted).length;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _RewardsSummaryCard(profile: profile),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.tips_and_updates_outlined),
                        title: const Text('Next Best Action'),
                        subtitle: Text(profile.nextBestAction),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Activities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completed $completedActivities/${activities.length} tasks',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    ...activities.map((RewardActivity activity) {
                      return _ActivityCard(activity: activity);
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Achievements',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unlocked ${profile.unlockedBadgesCount}/${badges.length} badges',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
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
                    final RewardBadge badge = badges[index];
                    return _BadgeCard(badge: badge);
                  },
                  childCount: badges.length,
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
  const _BadgeCard({required this.badge});

  final RewardBadge badge;

  @override
  Widget build(BuildContext context) {
    final Color unlockedColor = Theme.of(context).colorScheme.primary;
    final Color lockedColor = Theme.of(context).colorScheme.outline;

    return Container(
      decoration: BoxDecoration(
        color: badge.isUnlocked
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.isUnlocked
              ? unlockedColor.withValues(alpha: 0.55)
              : lockedColor.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  badge.isUnlocked ? 'Unlocked' : 'Locked',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: badge.isUnlocked ? unlockedColor : lockedColor,
                      ),
                ),
              ),
              Text(
                '+${badge.coinReward}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badge.isUnlocked
                    ? Colors.amber.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
              child: Text(
                badge.icon,
                style: TextStyle(
                  fontSize: 30,
                  color: badge.isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: (badge.isUnlocked ? unlockedColor : lockedColor)
                  .withValues(alpha: 0.12),
            ),
            child: Text(
              '${badge.currentProgress}/${badge.targetProgress}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: badge.progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: badge.isUnlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
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

class _RewardsSummaryCard extends StatelessWidget {
  const _RewardsSummaryCard({required this.profile});

  final FinRewardProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1E88E5), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 30),
              const SizedBox(width: 8),
              Text(
                '${profile.totalFinCoins} FinCoins',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${profile.currentRank} -> ${profile.nextRank}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: profile.progressToNextRank,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.coinsToNextRank <= 0
                ? 'You are at the highest rank tier.'
                : '${profile.coinsToNextRank} coins to unlock ${profile.nextRank}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final RewardActivity activity;

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        activity.isCompleted ? const Color(0xFF2E7D32) : const Color(0xFF1565C0);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(activity.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    activity.isCompleted ? 'Complete' : 'In progress',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              activity.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: LinearProgressIndicator(
                    value: activity.progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${activity.currentProgress}/${activity.targetProgress}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '+${activity.coinReward} FinCoins',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}