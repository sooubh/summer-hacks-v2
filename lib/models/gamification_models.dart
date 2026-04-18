class RewardBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isUnlocked;
  final int coinReward;
  final int currentProgress;
  final int targetProgress;

  RewardBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.coinReward = 0,
    this.currentProgress = 0,
    this.targetProgress = 1,
  });

  double get progress {
    if (targetProgress <= 0) {
      return isUnlocked ? 1 : 0;
    }
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

  int get remainingProgress {
    if (isUnlocked) {
      return 0;
    }
    return targetProgress - currentProgress;
  }
}

class RewardActivity {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int currentProgress;
  final int targetProgress;
  final int coinReward;
  final bool isCompleted;

  RewardActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.currentProgress,
    required this.targetProgress,
    required this.coinReward,
    required this.isCompleted,
  });

  double get progress {
    if (targetProgress <= 0) {
      return isCompleted ? 1 : 0;
    }
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

  int get remainingProgress {
    if (isCompleted) {
      return 0;
    }
    return targetProgress - currentProgress;
  }
}

class FinRewardProfile {
  final int totalFinCoins;
  final String currentRank;
  final String nextRank;
  final double progressToNextRank;
  final int coinsToNextRank;
  final int unlockedBadgesCount;
  final String nextBestAction;
  final List<RewardActivity> activities;
  final List<RewardBadge> badges;

  FinRewardProfile({
    required this.totalFinCoins,
    required this.currentRank,
    required this.nextRank,
    required this.progressToNextRank,
    required this.coinsToNextRank,
    required this.unlockedBadgesCount,
    required this.nextBestAction,
    required this.activities,
    required this.badges,
  });
}