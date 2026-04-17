import re

with open('lib/providers/dashboard_providers.dart', 'r', encoding='utf-8') as f:
    data = f.read()

old = '''  double monthlyGoalContribution = 0;
  for (final SavingsGoal goal in goals) {
    if (goal.status == GoalStatus.active) {
      monthlyGoalContribution +=
          ref.watch(savingsServiceProvider).recommendedMonthlyContribution(goal);
    }
  }'''

new = '''  double monthlyGoalContribution = 0;
  double totalSavings = 0;
  for (final SavingsGoal goal in goals) {
    totalSavings += goal.currentAmount;
    if (goal.status == GoalStatus.active) {
      monthlyGoalContribution +=
          ref.watch(savingsServiceProvider).recommendedMonthlyContribution(goal);
    }
  }'''
data = data.replace(old, new)


old2 = '''  return DashboardSnapshot(
    totalBalance: unified.totalBalance,'''
new2 = '''  return DashboardSnapshot(
    totalBalance: unified.totalBalance,
    totalSavings: totalSavings,'''

data = data.replace(old2, new2)

with open('lib/providers/dashboard_providers.dart', 'w', encoding='utf-8') as f:
    f.write(data)
