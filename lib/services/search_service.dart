import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'product', 'order', 'category'
  final Map<String, dynamic> data;
  final IconData icon;
  final Color color;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.data,
    required this.icon,
    required this.color,
  });
}

class SearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Enhanced caching with memory management
  static final Map<String, List<SearchResult>> _searchCache = {};
  static const int _cacheTimeout = 60000; // 1 minute
  static const int _maxCacheSize = 50; // Limit cache size
  static final Map<String, int> _cacheTimestamps = {};
  
  // Query throttling
  static Timer? _queryThrottle;
  static const int _throttleDelay = 300;

  static Future<List<SearchResult>> searchAll(String query) async {
    if (query.trim().isEmpty) return [];

    final searchQuery = query.toLowerCase().trim();
    
    // Check cache first
    if (_searchCache.containsKey(searchQuery)) {
      final timestamp = _cacheTimestamps[searchQuery] ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - timestamp < _cacheTimeout) {
        return _searchCache[searchQuery]!;
      }
    }

    // Throttle queries to prevent excessive API calls
    if (_queryThrottle?.isActive ?? false) {
      _queryThrottle!.cancel();
    }

    final completer = Completer<List<SearchResult>>();
    
    _queryThrottle = Timer(Duration(milliseconds: _throttleDelay), () async {
      try {
        final List<SearchResult> results = [];
        
        // Parallel search with timeout
        final futures = await Future.wait([
          _searchProducts(searchQuery).timeout(const Duration(seconds: 3)),
          _searchOrders(searchQuery).timeout(const Duration(seconds: 3)),
          _searchCategories(searchQuery).timeout(const Duration(seconds: 2)),
        ], eagerError: false);

        // Combine results
        for (final resultList in futures) {
          if (resultList is List<SearchResult>) {
            results.addAll(resultList);
          }
        }

        // Sort by relevance (simplified for performance)
        results.sort((a, b) {
          final aScore = _calculateRelevanceScore(a.title, searchQuery);
          final bScore = _calculateRelevanceScore(b.title, searchQuery);
          return bScore.compareTo(aScore);
        });

        final limitedResults = results.take(12).toList();
        
        // Cache management
        _manageCache();
        _searchCache[searchQuery] = limitedResults;
        _cacheTimestamps[searchQuery] = DateTime.now().millisecondsSinceEpoch;

        completer.complete(limitedResults);
      } catch (e) {
        print('Search error: $e');
        completer.complete([]);
      }
    });

    return completer.future;
  }

  static int _calculateRelevanceScore(String title, String query) {
    final lowerTitle = title.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    if (lowerTitle == lowerQuery) return 100;
    if (lowerTitle.startsWith(lowerQuery)) return 80;
    if (lowerTitle.contains(' $lowerQuery')) return 60;
    if (lowerTitle.contains(lowerQuery)) return 40;
    return 0;
  }

  static void _manageCache() {
    if (_searchCache.length >= _maxCacheSize) {
      // Remove oldest entries
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final toRemove = sortedEntries.take(_maxCacheSize ~/ 2);
      for (final entry in toRemove) {
        _searchCache.remove(entry.key);
        _cacheTimestamps.remove(entry.key);
      }
    }
  }

  static Future<List<SearchResult>> _searchProducts(String searchQuery) async {
    try {
      final results = <SearchResult>[];
      
      // Get all products and filter client-side for better search
      final snapshot = await _firestore
          .collection('products')
          .limit(15)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = (data['title'] as String? ?? '').toLowerCase();
        final categoryName = (data['categoryName'] as String? ?? '').toLowerCase(); // Fixed field name
        
        if (title.contains(searchQuery) || categoryName.contains(searchQuery)) {
          final price = data['price'];
          final priceStr = price != null ? '\$${price.toString()}' : 'Price not set';
          
          results.add(SearchResult(
            id: doc.id,
            title: data['title'] ?? 'Unnamed Product',
            subtitle: '${data['categoryName'] ?? 'Uncategorized'} • $priceStr', // Fixed field name
            type: 'product',
            data: data,
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF2196F3),
          ));
        }
      }
      
      return results;
    } catch (e) {
      print('Product search error: $e');
      return [];
    }
  }

  static Future<List<SearchResult>> _searchOrders(String searchQuery) async {
    try {
      final results = <SearchResult>[];
      
      final snapshot = await _firestore
          .collection('orders')
          .limit(8)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final orderId = doc.id.toLowerCase();
        final userName = (data['userName'] as String? ?? '').toLowerCase();
        final userEmail = (data['userEmail'] as String? ?? '').toLowerCase();
        
        if (orderId.contains(searchQuery) || 
            userName.contains(searchQuery) || 
            userEmail.contains(searchQuery)) {
          
          final orderDate = data['orderDate'];
          String dateStr = 'Unknown date';
          if (orderDate != null) {
            try {
              final timestamp = orderDate as Timestamp;
              final date = timestamp.toDate();
              dateStr = '${date.day}/${date.month}/${date.year}';
            } catch (e) {
              dateStr = 'Unknown date';
            }
          }
          
          results.add(SearchResult(
            id: doc.id,
            title: 'Order #${doc.id.substring(0, 8).toUpperCase()}',
            subtitle: '${data['userName'] ?? 'Unknown'} • $dateStr • ${data['orderStatus'] ?? 'Pending'}',
            type: 'order',
            data: data,
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFFFF9800),
          ));
        }
      }
      
      return results;
    } catch (e) {
      print('Order search error: $e');
      return [];
    }
  }

  static Future<List<SearchResult>> _searchCategories(String searchQuery) async {
    try {
      final results = <SearchResult>[];
      
      final snapshot = await _firestore
          .collection('categories')
          .limit(5)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final categoryName = (data['name'] as String? ?? '').toLowerCase(); // Categories use 'name' field
        
        if (categoryName.contains(searchQuery)) {
          results.add(SearchResult(
            id: doc.id,
            title: data['name'] ?? 'Unnamed Category', // Use 'name' field
            subtitle: 'Product Category',
            type: 'category',
            data: data,
            icon: Icons.category_outlined,
            color: const Color(0xFF4CAF50),
          ));
        }
      }
      
      return results;
    } catch (e) {
      print('Category search error: $e');
      return [];
    }
  }

  static void clearCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
    _queryThrottle?.cancel();
  }

  static void dispose() {
    _queryThrottle?.cancel();
    clearCache();
  }
} 