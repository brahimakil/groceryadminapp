import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/themes/app_theme.dart';
import 'package:grocery_admin_panel/providers/dark_theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:grocery_admin_panel/responsive.dart';
import 'package:grocery_admin_panel/services/search_service.dart';
import 'package:grocery_admin_panel/widgets/search_overlay.dart';
import 'package:grocery_admin_panel/inner_screens/edit_prod.dart';
import 'package:grocery_admin_panel/inner_screens/categories_screen.dart';
import 'package:grocery_admin_panel/inner_screens/all_orders_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Header extends StatefulWidget {
  const Header({
    Key? key,
    required this.fct,
    required this.title,
    this.showTextField = true,
  }) : super(key: key);
  
  final Function fct;
  final String title;
  final bool showTextField;

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> with TickerProviderStateMixin {
  late AnimationController _slideAnimController;
  late AnimationController _searchAnimController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _searchAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _showSearchOverlay = false;
  String _currentQuery = '';
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _slideAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimController,
      curve: Curves.easeOutCubic,
    ));

    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOut,
    ));

    _slideAnimController.forward();

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        _hideSearchResults();
      }
    });
  }

  @override
  void dispose() {
    _slideAnimController.dispose();
    _searchAnimController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _showSearchResults() {
    if (_overlayEntry != null) return;

    setState(() {
      _showSearchOverlay = true;
    });
    _searchAnimController.forward();

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideSearchResults,
        child: Material(
          color: Colors.black.withOpacity(0.1),
          child: Stack(
            children: [
              Positioned(
                top: Responsive.isMobile(context) ? 120 : 80,
                left: Responsive.isMobile(context) ? 16 : 20,
                right: 20,
                child: SearchOverlay(
                  query: _currentQuery,
                  onClose: _hideSearchResults,
                  onResultTap: _handleSearchResultTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSearchResults() {
    if (_overlayEntry == null) return;

    _searchAnimController.reverse().then((_) {
      _removeOverlay();
      if (mounted) {
        setState(() {
          _showSearchOverlay = false;
        });
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleSearchResultTap(SearchResult result) {
    _hideSearchResults();
    _searchFocusNode.unfocus();
    
    // Add a small delay to ensure overlay is properly disposed
    Future.delayed(const Duration(milliseconds: 100), () {
      _navigateToResult(result);
    });
  }

  void _navigateToResult(SearchResult result) {
    try {
      switch (result.type) {
        case 'product':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditProductScreen(
                id: result.id,
                title: result.data['title'] ?? 'Unnamed Product',
                price: result.data['price']?.toString() ?? '0',
                categoryName: result.data['categoryName'] ?? '',
                imageUrl: result.data['imageUrl'] ?? '',
                description: result.data['description'] ?? '',
                nutrients: result.data['nutrients'] ?? '',
                calories: result.data['calories'] ?? 0,
              ),
            ),
          ).catchError((error) {
            print('Navigation error: $error');
            _showSimpleDialog('Product', 'Could not open product for editing: ${result.title}');
          });
          break;
        case 'order':
          _showOrderDetailsDialog(result);
          break;
        case 'category':
          Navigator.pushNamed(context, CategoriesScreen.routeName).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Looking for category: ${result.title}'),
                duration: const Duration(seconds: 3),
                backgroundColor: AppTheme.secondaryColor,
              ),
            );
          }).catchError((error) {
            print('Navigation error: $error');
            _showSimpleDialog('Category', 'Could not open categories screen');
          });
          break;
      }
    } catch (e) {
      print('Navigation error: $e');
      _showSimpleDialog('Error', 'Could not navigate to ${result.type}: ${result.title}');
    }
  }

  void _showOrderDetailsDialog(SearchResult result) {
    final orderData = result.data;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppTheme.warningColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Text(
                'Order Details',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: Responsive.isMobile(context) ? double.maxFinite : 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderDetailRow('Order ID', result.id.substring(0, 12) + '...'),
              _buildOrderDetailRow('Customer', orderData['userName'] ?? 'Unknown'),
              _buildOrderDetailRow('Email', orderData['userEmail'] ?? 'N/A'),
              _buildOrderDetailRow('Status', orderData['orderStatus'] ?? 'Pending'),
              _buildOrderDetailRow('Total Price', '\$${(orderData['totalPrice'] ?? 0).toStringAsFixed(2)}'),
              _buildOrderDetailRow('Product Count', '${orderData['productCount'] ?? 0} items'),
              if (orderData['orderDate'] != null)
                _buildOrderDetailRow('Order Date', _formatOrderDate(orderData['orderDate'])),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
      children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'To manage this order, go to Orders section',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.neutral600,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllOrdersScreen(),
                ),
              );
            },
            child: const Text('View All Orders'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatOrderDate(dynamic orderDate) {
    try {
      if (orderDate is Timestamp) {
        final date = orderDate.toDate();
        return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return 'Unknown date';
    } catch (e) {
      return 'Unknown date';
    }
  }

  void _showSimpleDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Text(
              title,
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
        child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingLg),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowSm,
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: Row(
      children: [
        if (!Responsive.isDesktop(context))
              Container(
                margin: const EdgeInsets.only(right: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => widget.fct(),
                  tooltip: 'Open Menu',
                ),
              ),
            
        if (Responsive.isDesktop(context))
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTheme.headingMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Manage your grocery store',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.showTextField)
              Expanded(
                flex: Responsive.isDesktop(context) ? 3 : 4,
                      child: Container(
                  margin: EdgeInsets.only(
                    left: Responsive.isDesktop(context) ? AppTheme.spacingLg : 0,
                    right: AppTheme.spacingMd,
                  ),
                  child: AnimatedBuilder(
                    animation: _searchAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: _searchFocusNode.hasFocus
                                ? AppTheme.primaryColor
                                : Theme.of(context).dividerColor.withOpacity(0.5),
                            width: _searchFocusNode.hasFocus ? 2 : 1,
                          ),
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (value) {
                            setState(() {
                              _currentQuery = value;
                              _isSearching = value.isNotEmpty;
                            });
                            
                            if (_currentQuery.isNotEmpty && _searchFocusNode.hasFocus) {
                              if (_showSearchOverlay) {
                                _removeOverlay();
                              }
                              Future.delayed(const Duration(milliseconds: 50), () {
                                if (_searchFocusNode.hasFocus) {
                                  _showSearchResults();
                                }
                              });
                            } else {
                              _hideSearchResults();
                            }
                          },
                          onTap: () {
                            if (_currentQuery.isNotEmpty) {
                              _showSearchResults();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Search products, orders, categories...',
                            hintStyle: AppTheme.bodyMedium.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: _searchFocusNode.hasFocus 
                                  ? AppTheme.primaryColor 
                                  : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            ),
                            suffixIcon: _currentQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _currentQuery = '';
                                        _isSearching = false;
                                      });
                                      _hideSearchResults();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                              vertical: AppTheme.spacingMd,
                        ),
                      ),
                    ),
                      );
                    },
                  ),
                ),
              ),

            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.warningColor,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Notifications feature coming soon!'),
                          backgroundColor: AppTheme.warningColor,
                        ),
                      );
                    },
                    tooltip: 'Notifications',
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.account_circle_outlined,
                      color: AppTheme.successColor,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('User profile feature coming soon!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                    tooltip: 'User Profile',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}