import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/gamification_models.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';

final gamificationProvider = Provider<FinRewardProfile>((ref) {
  final snapshot = ref.watch(dashboardSnapshotProvider);
  
  int coins = 0;
  List<RewardBadge> badges = [];

  coins += (snapshot.totalSavings / 10).floor();

  if (snapshot.totalSavings > 0) {
    coins += 50; 
  }

  if (snapshot.safeToSpend > 0) {
    coins += 20; 
  }
  
  if (snapshot.burnRate < 500 && snapshot.burnRate > 0) {
    coins += 100;
  }

  badges.add(RewardBadge(
    id: 'first_save',
    name: 'First Saver',
    description: 'Save your first rupee to secure the future.',
    icon: '🌱',
    isUnlocked: snapshot.totalSavings > 0,
  ));

  badges.add(RewardBadge(
    id: 'budget_master',
    name: 'Budget Master',
    description: 'Maintain a positive safe-to-spend balance.',
    icon: '🛡️',
    isUnlocked: snapshot.safeToSpend > 0,
  ));

  badges.add(RewardBadge(
    id: 'low_burn',
    name: 'Low Speed Burner',
    description: 'Keep your daily burn rate below ₹500.',
    icon: '🔥',
    isUnlocked: snapshot.burnRate < 500 && snapshot.burnRate > 0,
  ));

  badges.add(RewardBadge(
    id: 'investor_mindset',
    name: 'Investor Mind',
    description: 'Accumulate over ₹10k in total savings.',
    icon: '📈',
    isUnlocked: snapshot.totalSavings > 10000,
  ));

  String currentRank = 'Novice';
  String nextRank = 'Bronze Saver';
  double progress = 0.0;

  if (coins < 200) {
    currentRank = 'Novice Saver';
    nextRank = 'Bronze Saver';
    progress = coins / 200.0;
  } else if (coins < 1000) {
    currentRank = 'Bronze Saver';
    nextRank = 'Silver Investor';
    progress = (coins - 200) / 800.0;
  } else if (coins < 5000) {
    currentRank = 'Silver Investor';
    nextRank = 'Gold Wealth Builder';
    progress = (coins - 1000) / 4000.0;
  } else {
    currentRank = 'Gold Wealth Builder';
    nextRank = 'Max Level';
    progress = 1.0;
  }

  return FinRewardProfile(
    totalFinCoins: coins,
    currentRank: currentRank,
    nextRank: nextRank,
    progressToNextRank: progress.clamp(0.0, 1.0),
    badges: badges,
  );
});