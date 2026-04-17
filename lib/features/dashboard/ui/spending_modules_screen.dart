import 'package:flutter/material.dart';

class SpendingModule {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final List<String> steps;
  final List<String> tips;

  const SpendingModule({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.steps,
    required this.tips,
  });
}

const List<SpendingModule> _modules = [
  SpendingModule(
    id: 'ecom',
    title: 'E-Commerce (Amazon/Flipkart)',
    icon: Icons.shopping_cart,
    description: 'Master the art of buying online without falling for fake discounts.',
    steps: [
      'Install price tracker extensions (like Keepa or PriceHistory).',
      'Add items to your cart and leave them for a day to sometimes get custom discounts.',
      'Check the seller rating, not just the product rating.',
      'Compare prices across different platforms before checking out.',
    ],
    tips: [
      'Big sales (like Big Billion Days) often inflate the MRP to show a larger discount percentage.',
      'Use credit/debit card offers specific to the platform.',
      'Student prime/premium accounts offer huge delivery savings.',
    ],
  ),
  SpendingModule(
    id: 'food',
    title: 'Food Delivery (Zomato/Swiggy)',
    icon: Icons.fastfood,
    description: 'Satisfy cravings while keeping delivery and surge fees in check.',
    steps: [
      'Open both apps and compare the final cart value (including taxes and delivery).',
      'Check if the restaurant has their own direct delivery app/number—it avoids 30% platform commissions.',
      'Apply custom coupon codes hidden in the offers section.',
    ],
    tips: [
      'Delivery platforms inflate menu prices. Eating in person is often 20% cheaper.',
      'Always check the delivery fee; sometimes a slightly more expensive item from a closer restaurant is cheaper overall.',
      'Consider subscriptions like Swiggy One if you order more than 4 times a month.',
    ],
  ),
  SpendingModule(
    id: 'rides',
    title: 'Ride Hailing (Uber/Ola/Rapido)',
    icon: Icons.directions_car,
    description: 'Get around the city without draining your wallet on surge pricing.',
    steps: [
      'Compare across Uber, Ola, and Rapido/Namma Yatri.',
      'If surge pricing is high, schedule the ride 30 minutes in advance to lock in a lower rate.',
      'Walk to a main road or landmark to reduce routing distance and save money.',
    ],
    tips: [
      'Bikes and Autos are substantially cheaper for solo travel.',
      'Public transport like Metro/Bus linked with last-mile bikes is the ultimate student hack.',
    ],
  ),
  SpendingModule(
    id: 'streaming',
    title: 'Streaming Apps (Netflix/Spotify)',
    icon: Icons.play_circle_filled,
    description: 'Enjoy music and movies without paying full price.',
    steps: [
      'Verify your student status using your university email (UNiDAYS/SheerID).',
      'Gather friends to split a family plan.',
      'Only subscribe to one video service a month. Binge what you want, then cancel and switch the next month.',
    ],
    tips: [
      'Spotify Student is 50% off.',
      'Never pay for multiple streaming services simultaneously if you only watch on weekends.',
    ],
  ),
  SpendingModule(
    id: 'flights',
    title: 'Flight Tickets',
    icon: Icons.flight,
    description: 'Book flights smartly to save thousands on trips home.',
    steps: [
      'Use aggregators like Skyscanner or Google Flights to find the cheapest dates.',
      'Always search in Incognito mode to avoid cookies raising prices on repeated searches.',
      'Book directly on the airline website once you find the best flight on aggregators.',
    ],
    tips: [
      'Airlines offer Student discounts (often 5-10% off base fare and extra baggage). Always carry your ID.',
      'Tuesdays and Wednesdays are usually the cheapest days to fly.',
    ],
  ),
  SpendingModule(
    id: 'hotels',
    title: 'Hotel Bookings',
    icon: Icons.hotel,
    description: 'Find safe and affordable stays for trips and hackathons.',
    steps: [
      'Search on Agoda, Booking.com, or MakeMyTrip.',
      'Shortlist 2-3 hotels and call them directly. Ask if they can beat the online price if you book directly (they save 15% commission).',
      'Check reviews specifically on Google Maps, not just the booking site.',
    ],
    tips: [
      'Hostels (like Zostel/Moustache) are 70% cheaper than hotels and safer for solo students.',
    ],
  ),
  SpendingModule(
    id: 'groceries',
    title: 'Quick Groceries (Blinkit/Zepto)',
    icon: Icons.shopping_basket,
    description: 'Manage late-night snack runs without massive markups.',
    steps: [
      'Create a weekly list rather than ordering 3-4 times a week to save on delivery/handling fees.',
      'Check your local offline store. Quick commerce marks up certain items by 10-15%.',
      'Avoid the impulse-buy sections at checkout on these apps.',
    ],
    tips: [
      'Buying large packs (e.g., 1kg vs 100g) significantly reduces per-unit cost.',
    ],
  ),
  SpendingModule(
    id: 'fashion',
    title: 'Fashion & Clothing (Myntra/Ajio)',
    icon: Icons.checkroom,
    description: 'Build a solid wardrobe on a tight student budget.',
    steps: [
      'Add items to your wishlist and wait. Prices on clothing drop drastically during End of Reason Sales.',
      'Check the return policy carefully before buying high-discount items (some are non-returnable).',
      'Filter by customer rating and verify with photo reviews.',
    ],
    tips: [
      'Invest in basics (plain tees, good jeans, solid sneakers) before buying trendy items.',
      'Use specific bank cards during sales for an extra 10% off.',
    ],
  ),
  SpendingModule(
    id: 'electronics',
    title: 'Electronics & Gadgets',
    icon: Icons.laptop_mac,
    description: 'Buy essentials like laptops and headphones at the best rates.',
    steps: [
      'Register for Apple UNiDAYS or Samsung Student Advantage using your college ID.',
      'Wait for festive sales (Diwali/Dussehra) for the biggest price drops.',
      'Consider refurbished items from verified sellers (Amazon Renewed) with warranties.',
    ],
    tips: [
      'Always check offline stores (Croma/Reliance). Sometimes they match online prices and give immediate delivery.',
    ],
  ),
  SpendingModule(
    id: 'software',
    title: 'Software & Subscriptions',
    icon: Icons.developer_mode,
    description: 'Tools for coding and design for free or cheap.',
    steps: [
      'Sign up for the GitHub Student Developer Pack using your .edu email for dozens of free pro tools.',
      'Check if your university provides free MS Office 365 or Adobe Creative Cloud.',
      'Search for Open Source alternatives (e.g., Figma -> Penpot, Photoshop -> Photopea).',
    ],
    tips: [
      'Notion is free for students.',
      'Never pay retail for JetBrains IDEs or Canva if you have a valid college ID.',
    ],
  ),
  SpendingModule(
    id: 'movies',
    title: 'Movie Tickets (BookMyShow)',
    icon: Icons.movie,
    description: 'Enjoy cinema outings securely and cheaply.',
    steps: [
      'Check the "Offers" section on BookMyShow before selecting seats.',
      'See if any of your debit/credit cards have a 1+1 or percentage discount.',
      'Go for morning or weekday shows instead of prime-time weekend slots.',
    ],
    tips: [
      'Avoid buying food at the concession stand. Eat before or after the movie to save 60%.',
    ],
  ),
  SpendingModule(
    id: 'courses',
    title: 'Online Courses (Udemy/Coursera)',
    icon: Icons.school,
    description: 'Upskill without paying hefty subscription fees.',
    steps: [
      'Never buy a Udemy course at full price. Add it to your cart, and within a week it will drop to ₹400-500.',
      'Use the "Audit Course" feature on Coursera to access videos and reading material entirely for free.',
      'Apply for Coursera Financial Aid if you absolutely need the certificate.',
    ],
    tips: [
      'YouTube often has complete courses equivalent to or better than paid ones (e.g., FreeCodeCamp).',
    ],
  ),
  SpendingModule(
    id: 'gym',
    title: 'Fitness & Gyms',
    icon: Icons.fitness_center,
    description: 'Stay healthy without overpaying for unused memberships.',
    steps: [
      'Start with a free trial to check the gym crowding and equipment.',
      'Never pay the quoted price. Gyms almost always negotiate.',
      'Commit to a 1 or 3-month plan first. Dont buy the yearly plan until you have a confirmed habit.',
    ],
    tips: [
      'Check if your college has a free internal gym.',
      'Apps like Cult Fit offer student discounts, ask customer support.',
    ],
  ),
  SpendingModule(
    id: 'books',
    title: 'Books & Stationery',
    icon: Icons.menu_book,
    description: 'Acquire study materials smartly.',
    steps: [
      'Ask seniors if they are selling or giving away their old textbooks.',
      'Check local second-hand book markets (like Daryaganj or College Street).',
      'Use the library heavily for reference books rather than buying them.',
    ],
    tips: [
      'PDFs and Kindle versions are cheaper and easier to carry.',
    ],
  ),
  SpendingModule(
    id: 'gaming',
    title: 'Gaming (Steam/Epic)',
    icon: Icons.sports_esports,
    description: 'Fuel your gaming hobby economically.',
    steps: [
      'Claim the free weekly games on the Epic Games Store.',
      'Wishlist games on Steam and only buy during the major Summer or Winter sales.',
      'Use services like Xbox Game Pass for a massive library at a low monthly cost.',
    ],
    tips: [
      'Avoid microtransactions and "loot boxes". They are designed to extract continuous money.',
    ],
  ),
  SpendingModule(
    id: 'pharmacy',
    title: 'Pharmacy & Health (1mg/Apollo)',
    icon: Icons.local_pharmacy,
    description: 'Buy medicines safely and at discounted rates.',
    steps: [
      'Order online for flat 15-20% discounts compared to offline MRPS.',
      'Compare prices between PharmEasy, Tata 1mg, and Apollo.',
      'Ask your doctor to prescribe the generic salt name instead of the brand name—generics are up to 80% cheaper.',
    ],
    tips: [
      'For chronic or regular medications, use the subscription feature to lock in extra discounts.',
    ],
  ),
  SpendingModule(
    id: 'cloud',
    title: 'Cloud Storage',
    icon: Icons.cloud,
    description: 'Manage your digital files without paying for space.',
    steps: [
      'Sign in to Google Workspace or OneDrive with your .edu college email—many offer 1TB to Unlimited storage for free.',
      'Clear out large video files or duplicate photos using a storage analyzer.',
      'Use multiple free accounts organized by domain (one for photos, one for work).',
    ],
    tips: [
      'Never back up unnecessary cache or node_modules to the cloud.',
    ],
  ),
  SpendingModule(
    id: 'events',
    title: 'Event & Concert Tickets',
    icon: Icons.confirmation_number,
    description: 'Attend fests and concerts legally and cheaply.',
    steps: [
      'Buy Early Bird tickets; prices rise heavily in phases.',
      'Check if there is a student pass tier (often much cheaper).',
      'Look for volunteer opportunities. Organizing teams let you attend for free in exchange for a few hours of work.',
    ],
    tips: [
      'Beware of ticket scalpers on Instagram/Twitter. Fake QR code scams are very common.',
    ],
  ),
  SpendingModule(
    id: 'investing',
    title: 'Investment Platforms (Zerodha/Groww)',
    icon: Icons.trending_up,
    description: 'Start wealth generation securely.',
    steps: [
      'Compare Account Maintenance Charges (AMC). Some platforms charge ₹300/year, others are zero.',
      'Always select "Direct" Mutual Funds instead of "Regular" ones to save 1% in commissions annually.',
      'Start a small SIP (Systematic Investment Plan) rather than gambling on individual stocks.',
    ],
    tips: [
      'Beware of unregulated "Crypto" or "Forex" platforms promising guaranteed daily returns.',
    ],
  ),
  SpendingModule(
    id: 'freelance',
    title: 'Freelance & Gig Platforms',
    icon: Icons.work,
    description: 'Manage your gig earnings without massive fee cuts.',
    steps: [
      'Understand the platform fee (Upwork/Fiverr take up to 20%). Price your services to cover it.',
      'Withdraw money in larger batches rather than small sums to save on flat withdrawal fees.',
      'Set up a separate bank account specifically to track your freelance income for easier taxation.',
    ],
    tips: [
      'Never accept work outside the platform if interacting with an unverified client to avoid getting scammed.',
    ],
  ),
];

class LearningModulesScreen extends StatelessWidget {
  const LearningModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Spending Modules'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _modules.length,
        itemBuilder: (context, index) {
          final module = _modules[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ModuleDetailScreen(module: module),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        module.icon,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            module.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ModuleDetailScreen extends StatelessWidget {
  final SpendingModule module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(module.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Icon(
                  module.icon,
                  size: 64,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              module.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              module.description,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              'Action Steps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            ...module.steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Theme.of(context).colorScheme.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Pro Tips',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...module.tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                tip,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
