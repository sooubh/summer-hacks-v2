import 'dart:math';

List<Map<String, dynamic>> generateDummyTransactions() {
  final List<Map<String, dynamic>> dummies = [];
  
  final templates = [
    {'title': 'Swiggy Order', 'amount': [150, 450], 'cat': 'food', 'src': 'UPI'},
    {'title': 'Uber Ride', 'amount': [100, 350], 'cat': 'travel', 'src': 'Card'},
    {'title': 'Amazon Shopping', 'amount': [500, 2500], 'cat': 'shopping', 'src': 'UPI'},
    {'title': 'Zomato Lunch', 'amount': [200, 500], 'cat': 'food', 'src': 'Paytm'},
    {'title': 'Netflix Subscription', 'amount': [199, 649], 'cat': 'entertainment', 'src': 'Card'},
    {'title': 'Spotify Premium', 'amount': [119, 119], 'cat': 'entertainment', 'src': 'UPI'},
    {'title': 'Blinkit Groceries', 'amount': [100, 600], 'cat': 'grocery', 'src': 'UPI'},
    {'title': 'Zepto Order', 'amount': [80, 400], 'cat': 'grocery', 'src': 'UPI'},
    {'title': 'Ola Cab', 'amount': [90, 300], 'cat': 'travel', 'src': 'Paytm'},
    {'title': 'Rapido Bike Ride', 'amount': [30, 90], 'cat': 'travel', 'src': 'UPI'},
    {'title': 'Jio Recharge', 'amount': [239, 749], 'cat': 'bills', 'src': 'GPay'},
    {'title': 'Airtel Broadband', 'amount': [799, 1099], 'cat': 'bills', 'src': 'Card'},
    {'title': 'BookMyShow', 'amount': [300, 800], 'cat': 'entertainment', 'src': 'Card'},
    {'title': 'Flipkart Sale', 'amount': [400, 3000], 'cat': 'shopping', 'src': 'UPI'},
    {'title': 'Myntra Fashion', 'amount': [600, 2000], 'cat': 'shopping', 'src': 'Card'},
    {'title': 'IRCTC Ticket', 'amount': [300, 1500], 'cat': 'travel', 'src': 'UPI'},
    {'title': 'MakeMyTrip Flight', 'amount': [3000, 6000], 'cat': 'travel', 'src': 'Card'},
    {'title': 'Medical Store', 'amount': [150, 800], 'cat': 'health', 'src': 'UPI'},
    {'title': 'Electricity Bill', 'amount': [800, 2500], 'cat': 'bills', 'src': 'Paytm'},
    {'title': 'Gym Membership', 'amount': [1500, 3000], 'cat': 'health', 'src': 'UPI'},
  ];

  final rand = Random();

  for (int i = 0; i < 40; i++) {
    final t = templates[rand.nextInt(templates.length)];
    final amtRange = t['amount'] as List<int>;
    final amount = amtRange[0] + rand.nextInt(amtRange[1] - amtRange[0] + 1);
    
    dummies.add({
      'title': t['title'],
      'amount': amount.toDouble(),
      'cat': t['cat'],
      'src': t['src'],
      'isIncome': false,
    });
  }

  // Inject some incomes
  dummies.insert(5, {'title': 'Freelance Project', 'amount': 8000.0, 'cat': 'salary', 'src': 'Bank', 'isIncome': true});
  dummies.insert(15, {'title': 'Pocket Money', 'amount': 5000.0, 'cat': 'salary', 'src': 'Bank', 'isIncome': true});
  dummies.insert(25, {'title': 'Internship Stipend', 'amount': 15000.0, 'cat': 'salary', 'src': 'Bank', 'isIncome': true});

  return dummies;
}
