import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get total counts
  Future<Map<String, int>> getTotalCounts() async {
    try {
      final results = await Future.wait([
        _firestore.collection('products').get(),
        _firestore.collection('orders').get(),
        _firestore.collection('categories').get(),
      ]);

      return {
        'products': results[0].docs.length,
        'orders': results[1].docs.length,
        'categories': results[2].docs.length,
      };
    } catch (e) {
      print('Error getting total counts: $e');
      return {'products': 0, 'orders': 0, 'categories': 0};
    }
  }

  // Get revenue data
  Future<Map<String, double>> getRevenueData() async {
    try {
      final ordersSnapshot = await _firestore.collection('orders').get();
      
      double totalRevenue = 0;
      double todayRevenue = 0;
      double weekRevenue = 0;
      double monthRevenue = 0;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);
      
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final totalPrice = (data['totalPrice'] ?? 0).toDouble();
        final orderDate = (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        totalRevenue += totalPrice;
        
        if (orderDate.isAfter(today)) {
          todayRevenue += totalPrice;
        }
        
        if (orderDate.isAfter(weekStart)) {
          weekRevenue += totalPrice;
        }
        
        if (orderDate.isAfter(monthStart)) {
          monthRevenue += totalPrice;
        }
      }
      
      return {
        'total': totalRevenue,
        'today': todayRevenue,
        'week': weekRevenue,
        'month': monthRevenue,
      };
    } catch (e) {
      print('Error getting revenue data: $e');
      return {'total': 0, 'today': 0, 'week': 0, 'month': 0};
    }
  }

  // Get daily sales for the last 7 days
  Future<List<Map<String, dynamic>>> getDailySales() async {
    try {
      final ordersSnapshot = await _firestore.collection('orders').get();
      final Map<String, double> dailyRevenue = {};
      
      // Initialize last 7 days with 0
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateFormat('MM/dd').format(date);
        dailyRevenue[dateKey] = 0;
      }
      
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final orderDate = (data['orderDate'] as Timestamp?)?.toDate();
        final totalPrice = (data['totalPrice'] ?? 0).toDouble();
        
        if (orderDate != null) {
          final dateKey = DateFormat('MM/dd').format(orderDate);
          if (dailyRevenue.containsKey(dateKey)) {
            dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + totalPrice;
          }
        }
      }
      
      return dailyRevenue.entries
          .map((entry) => {
                'date': entry.key,
                'revenue': entry.value,
              })
          .toList();
    } catch (e) {
      print('Error getting daily sales: $e');
      return [];
    }
  }

  // Get category distribution
  Future<List<Map<String, dynamic>>> getCategoryDistribution() async {
    try {
      final productsSnapshot = await _firestore.collection('products').get();
      final Map<String, int> categoryCount = {};
      
      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final category = data['productCategory']?.toString() ?? 'Other';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
      
      final result = categoryCount.entries
          .map((entry) => {
                'name': entry.key,
                'count': entry.value,
              })
          .toList();
      
      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return result;
    } catch (e) {
      print('Error getting category distribution: $e');
      return [];
    }
  }

  // Get order status distribution
  Future<List<Map<String, dynamic>>> getOrderStatusDistribution() async {
    try {
      final ordersSnapshot = await _firestore.collection('orders').get();
      final Map<String, int> statusCount = {};
      
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString() ?? 'pending';
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }
      
      return statusCount.entries
          .map((entry) => {
                'status': entry.key,
                'count': entry.value,
              })
          .toList();
    } catch (e) {
      print('Error getting order status distribution: $e');
      return [];
    }
  }

  // Get recent activity
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      final recentOrders = await _firestore
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .limit(5)
          .get();
      
      return recentOrders.docs.map((doc) {
        final data = doc.data();
        final userName = data['userName']?.toString() ?? 'Unknown User';
        final totalPrice = (data['totalPrice'] ?? 0).toDouble();
        final orderDate = (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        return {
          'title': 'New Order',
          'subtitle': 'Order from $userName - \$${totalPrice.toStringAsFixed(2)}',
          'time': _formatTimeAgo(orderDate),
          'type': 'order',
        };
      }).toList();
    } catch (e) {
      print('Error getting recent activity: $e');
      return [];
    }
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    try {
      final ordersSnapshot = await _firestore.collection('orders').get();
      final Map<String, int> productSales = {};
      
      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        final products = orderData['products'] as List<dynamic>? ?? [];
        
        for (var product in products) {
          if (product is Map<String, dynamic>) {
            final productId = product['productId']?.toString() ?? '';
            if (productId.isNotEmpty) {
              final quantity = product['quantity'] ?? 1;
              final quantityInt = quantity is int ? quantity : (quantity as num).toInt();
              productSales[productId] = (productSales[productId] ?? 0) + quantityInt;
            }
          }
        }
      }
      
      // Get product details for top selling products
      final topProductIds = productSales.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      
      final List<Map<String, dynamic>> topProducts = [];
      
      for (var entry in topProductIds.take(5)) {
        try {
          final productDoc = await _firestore.collection('products').doc(entry.key).get();
          if (productDoc.exists) {
            final productData = productDoc.data()!;
            topProducts.add({
              'id': entry.key,
              'title': productData['title']?.toString() ?? 'Unknown Product',
              'sales': entry.value,
              'price': (productData['price'] ?? 0).toDouble(),
              'imageUrl': productData['imageUrl']?.toString(),
            });
          }
        } catch (e) {
          print('Error getting product ${entry.key}: $e');
        }
      }
      
      return topProducts;
    } catch (e) {
      print('Error getting top selling products: $e');
      return [];
    }
  }

  // Helper method to format time ago
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 