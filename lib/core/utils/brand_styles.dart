import 'package:flutter/material.dart';

class BrandStyles {
  static Color getColor(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('swiggy')) return const Color(0xFFFC8019);
    if (lowerTitle.contains('zomato')) return const Color(0xFFE23744);
    if (lowerTitle.contains('uber')) return Colors.black;
    if (lowerTitle.contains('ola')) return const Color(0xFFDCE24C);
    if (lowerTitle.contains('rapido')) return const Color(0xFFF9C70F);
    if (lowerTitle.contains('amazon')) return const Color(0xFFFF9900);
    if (lowerTitle.contains('flipkart')) return const Color(0xFF047BD5);
    if (lowerTitle.contains('myntra')) return const Color(0xFFF13AB1);
    if (lowerTitle.contains('netflix')) return const Color(0xFFE50914);
    if (lowerTitle.contains('spotify')) return const Color(0xFF1DB954);
    if (lowerTitle.contains('blinkit')) return const Color(0xFFF4CD2B);
    if (lowerTitle.contains('zepto')) return const Color(0xFF3F0071);
    if (lowerTitle.contains('paytm')) return const Color(0xFF00B9F1);
    if (lowerTitle.contains('phonepe')) return const Color(0xFF002970);
    if (lowerTitle.contains('google pay') || lowerTitle.contains('gpay')) return const Color(0xFFEA4335);
    if (lowerTitle.contains('dmart')) return const Color(0xFF00A251);
    if (lowerTitle.contains('bookmyshow')) return const Color(0xFFF84464);
    if (lowerTitle.contains('jio')) return const Color(0xFFE51A22);
    if (lowerTitle.contains('airtel')) return const Color(0xFFE40000);
    if (lowerTitle.contains('irctc')) return const Color(0xFF203870);
    if (lowerTitle.contains('makemytrip')) return const Color(0xFFD62A29);
    if (lowerTitle.contains('croma')) return const Color(0xFF00C0AB);
    if (lowerTitle.contains('salary') || lowerTitle.contains('income')) return Colors.green.shade600;
    return Colors.blueGrey;
  }

  static IconData getIcon(String title, String category) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('swiggy') || lowerTitle.contains('zomato')) return Icons.restaurant;
    if (lowerTitle.contains('uber') || lowerTitle.contains('ola') || lowerTitle.contains('rapido')) return Icons.directions_car;
    if (lowerTitle.contains('amazon') || lowerTitle.contains('flipkart') || lowerTitle.contains('myntra')) return Icons.shopping_bag;
    if (lowerTitle.contains('netflix') || lowerTitle.contains('spotify')) return Icons.play_arrow;
    if (lowerTitle.contains('blinkit') || lowerTitle.contains('zepto') || lowerTitle.contains('dmart')) return Icons.shopping_basket;
    if (lowerTitle.contains('bookmyshow')) return Icons.movie;
    if (lowerTitle.contains('irctc') || lowerTitle.contains('makemytrip')) return Icons.train;
    if (lowerTitle.contains('jio') || lowerTitle.contains('airtel')) return Icons.phone_android;
    if (lowerTitle.contains('salary') || lowerTitle.contains('income')) return Icons.account_balance;

    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('food')) return Icons.fastfood;
    if (lowerCat.contains('travel')) return Icons.commute;
    if (lowerCat.contains('shop')) return Icons.store;
    if (lowerCat.contains('grocery')) return Icons.local_grocery_store;
    if (lowerCat.contains('med') || lowerCat.contains('health')) return Icons.medical_services;
    if (lowerCat.contains('entertain')) return Icons.sports_esports;
    if (lowerCat.contains('bill') || lowerCat.contains('utility')) return Icons.receipt_long;
    
    return Icons.receipt;
  }
}
