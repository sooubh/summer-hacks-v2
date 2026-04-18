class RewardBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isUnlocked;

  RewardBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });
}

class FinRewardProfile {
  final int totalFinCoins;
  final String currentRank;
  final String nextRank;
  final double progressToNextRank;
  final List<RewardBadge> badges;

  FinRewardProfile({
    required this.totalFinCoins,
    required this.currentRank,
    required this.nextRank,
    required this.progressToNextRank,
    required this.badges,
  });
}