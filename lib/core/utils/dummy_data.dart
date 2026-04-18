import 'dart:math';

List<Map<String, dynamic>> generateDummyTransactions() {
  final List<Map<String, dynamic>> dummies = [];

  final templates = [
    {'title': 'Swiggy Order', 'amount': [150, 450], 'cat': 'food', 'src': 'Google Pay', 'channel': 'upi'},
    {'title': 'Uber Ride', 'amount': [100, 350], 'cat': 'travel', 'src': 'PhonePe', 'channel': 'upi'},
    {'title': 'Amazon Shopping', 'amount': [500, 2500], 'cat': 'shopping', 'src': 'Amazon Pay', 'channel': 'upi'},
    {'title': 'Zomato Lunch', 'amount': [200, 500], 'cat': 'food', 'src': 'Paytm', 'channel': 'upi'},
    {'title': 'Netflix Subscription', 'amount': [199, 649], 'cat': 'entertainment', 'src': 'HDFC Debit Card', 'channel': 'card'},
    {'title': 'Spotify Premium', 'amount': [119, 119], 'cat': 'entertainment', 'src': 'Google Pay', 'channel': 'upi'},
    {'title': 'Blinkit Groceries', 'amount': [100, 600], 'cat': 'grocery', 'src': 'PhonePe', 'channel': 'upi'},
    {'title': 'Zepto Order', 'amount': [80, 400], 'cat': 'grocery', 'src': 'Paytm', 'channel': 'upi'},
    {'title': 'Ola Cab', 'amount': [90, 300], 'cat': 'travel', 'src': 'Google Pay', 'channel': 'upi'},
    {'title': 'Rapido Bike Ride', 'amount': [30, 120], 'cat': 'travel', 'src': 'Cash', 'channel': 'cash'},
    {'title': 'Jio Recharge', 'amount': [239, 749], 'cat': 'bills', 'src': 'Google Pay', 'channel': 'upi'},
    {'title': 'Airtel Broadband', 'amount': [799, 1499], 'cat': 'bills', 'src': 'SBI Credit Card', 'channel': 'card'},
    {'title': 'BookMyShow', 'amount': [300, 800], 'cat': 'entertainment', 'src': 'PhonePe', 'channel': 'upi'},
    {'title': 'Flipkart Sale', 'amount': [400, 3000], 'cat': 'shopping', 'src': 'Paytm', 'channel': 'upi'},
    {'title': 'Myntra Fashion', 'amount': [600, 2000], 'cat': 'shopping', 'src': 'ICICI Debit Card', 'channel': 'card'},
    {'title': 'IRCTC Ticket', 'amount': [300, 1500], 'cat': 'travel', 'src': 'BHIM UPI', 'channel': 'upi'},
    {'title': 'MakeMyTrip Flight', 'amount': [3000, 6500], 'cat': 'travel', 'src': 'Axis Credit Card', 'channel': 'card'},
    {'title': 'Medical Store', 'amount': [150, 800], 'cat': 'health', 'src': 'Cash', 'channel': 'cash'},
    {'title': 'Electricity Bill', 'amount': [800, 2500], 'cat': 'bills', 'src': 'Amazon Pay', 'channel': 'upi'},
    {'title': 'Gym Membership', 'amount': [1500, 3000], 'cat': 'health', 'src': 'Bank Transfer', 'channel': 'bank_transfer'},
    {'title': 'Cafe Coffee Day', 'amount': [120, 420], 'cat': 'food', 'src': 'PhonePe', 'channel': 'upi'},
    {'title': 'Dominos Dinner', 'amount': [250, 780], 'cat': 'food', 'src': 'Google Pay', 'channel': 'upi'},
    {'title': 'Dmart Groceries', 'amount': [650, 2300], 'cat': 'grocery', 'src': 'Cash', 'channel': 'cash'},
    {'title': 'Apollo Pharmacy', 'amount': [180, 900], 'cat': 'health', 'src': 'Paytm', 'channel': 'upi'},
    {'title': 'Local Kirana', 'amount': [90, 460], 'cat': 'grocery', 'src': 'Cash', 'channel': 'cash'},
    {'title': 'Electric Scooter Charge', 'amount': [160, 420], 'cat': 'travel', 'src': 'CRED', 'channel': 'upi'},
    {'title': 'NPS Contribution', 'amount': [1000, 2500], 'cat': 'investment', 'src': 'Bank Transfer', 'channel': 'bank_transfer'},
    {'title': 'Mutual Fund SIP', 'amount': [1500, 4000], 'cat': 'investment', 'src': 'Bank Transfer', 'channel': 'bank_transfer'},
    {'title': 'Mobile Accessories', 'amount': [250, 1800], 'cat': 'shopping', 'src': 'Amazon Pay', 'channel': 'upi'},
    {'title': 'College Printouts', 'amount': [60, 250], 'cat': 'education', 'src': 'Cash', 'channel': 'cash'},
    {'title': 'Online Course', 'amount': [499, 2999], 'cat': 'education', 'src': 'Google Pay', 'channel': 'upi'},
    {'title': 'Hostel Utilities', 'amount': [400, 1200], 'cat': 'bills', 'src': 'PhonePe', 'channel': 'upi'},
    {'title': 'Stationery', 'amount': [80, 350], 'cat': 'education', 'src': 'Paytm', 'channel': 'upi'},
    {'title': 'Fuel Refill', 'amount': [200, 1300], 'cat': 'travel', 'src': 'Cash', 'channel': 'cash'},
    {'title': 'Weekend Movie Snacks', 'amount': [180, 550], 'cat': 'entertainment', 'src': 'PhonePe', 'channel': 'upi'},
    {'title': 'Laptop EMI', 'amount': [1800, 3200], 'cat': 'bills', 'src': 'Bank Transfer', 'channel': 'bank_transfer'},
    {'title': 'Exam Fees', 'amount': [900, 2200], 'cat': 'education', 'src': 'Google Pay', 'channel': 'upi'},
    {'title': 'Courier Charges', 'amount': [70, 320], 'cat': 'shopping', 'src': 'Cash', 'channel': 'cash'},
    {'title': 'Salon Visit', 'amount': [180, 850], 'cat': 'health', 'src': 'Paytm', 'channel': 'upi'},
    {'title': 'Petrol Pump Snack', 'amount': [60, 220], 'cat': 'food', 'src': 'Cash', 'channel': 'cash'},
  ];

  final rand = Random();

  for (int i = 0; i < 75; i++) {
    final t = templates[rand.nextInt(templates.length)];
    final amtRange = t['amount'] as List<int>;
    final amount = amtRange[0] + rand.nextInt(amtRange[1] - amtRange[0] + 1);

    dummies.add({
      'title': t['title'],
      'amount': amount.toDouble(),
      'cat': t['cat'],
      'src': t['src'],
      'channel': t['channel'],
      'isIncome': false,
    });
  }

  // Inject some incomes
  dummies.insert(5, {
    'title': 'Freelance Project',
    'amount': 8000.0,
    'cat': 'salary',
    'src': 'Bank Transfer',
    'channel': 'bank_transfer',
    'isIncome': true,
  });
  dummies.insert(15, {
    'title': 'Pocket Money',
    'amount': 5000.0,
    'cat': 'salary',
    'src': 'Bank Transfer',
    'channel': 'bank_transfer',
    'isIncome': true,
  });
  dummies.insert(25, {
    'title': 'Internship Stipend',
    'amount': 15000.0,
    'cat': 'salary',
    'src': 'Bank Transfer',
    'channel': 'bank_transfer',
    'isIncome': true,
  });
  dummies.insert(35, {
    'title': 'Tutoring Income',
    'amount': 4200.0,
    'cat': 'salary',
    'src': 'Bank Transfer',
    'channel': 'bank_transfer',
    'isIncome': true,
  });

  return dummies;
}
