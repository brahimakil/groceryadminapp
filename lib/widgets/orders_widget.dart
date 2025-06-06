import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/themes/app_theme.dart';
import 'package:grocery_admin_panel/services/global_method.dart';
import 'package:grocery_admin_panel/screens/loading_manager.dart';
import 'package:provider/provider.dart';
import '../providers/dark_theme_provider.dart';
import '../responsive.dart';
import 'dart:convert';

class OrdersWidget extends StatefulWidget {
  const OrdersWidget({
    Key? key,
    required this.orderId,
      required this.userId,
      required this.userName,
    required this.orderDate,
    required this.orderStatus,
    required this.totalPrice,
    required this.productCount,
  }) : super(key: key);
  
  final String orderId, userId, userName, orderStatus;
  final Timestamp orderDate;
  final double totalPrice;
  final int productCount;
  
  @override
  State<OrdersWidget> createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).darkTheme;
    final isMobile = Responsive.isMobile(context);
    
    return LoadingManager(
      isLoading: _isLoading,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - _slideAnimation.value)),
            child: Opacity(
              opacity: _slideAnimation.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: isDark ? AppTheme.neutral700 : AppTheme.neutral200,
                  ),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Row(
          children: [
            _buildOrderIcon(),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${widget.orderId.substring(0, 8)}',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    widget.userName,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _buildOrderDetails(),
        const SizedBox(height: AppTheme.spacingMd),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildOrderIcon(),
        const SizedBox(width: AppTheme.spacingMd),
        
        // Order Info
              Expanded(
          flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              Text(
                'Order #${widget.orderId.substring(0, 8)}',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
                            Text(
                widget.userName,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.neutral500,
                ),
                            ),
                          ],
                        ),
        ),
        
        // Order Details
        Expanded(
          flex: 3,
          child: _buildOrderDetails(),
        ),
        
        // Status
        _buildStatusBadge(),
        
        const SizedBox(width: AppTheme.spacingMd),
        
        // Actions
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildOrderIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: _getStatusGradient(),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: const Icon(
        Icons.shopping_bag_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildOrderDetails() {
    final orderDate = widget.orderDate.toDate();
    final formattedDate = '${orderDate.day}/${orderDate.month}/${orderDate.year}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                        Row(
                          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppTheme.neutral400,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              formattedDate,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutral500,
                              ),
                            ),
                          ],
                        ),
        const SizedBox(height: AppTheme.spacingXs),
                        Row(
                          children: [
            Icon(
              Icons.shopping_cart_rounded,
              size: 16,
              color: AppTheme.neutral400,
            ),
            const SizedBox(width: AppTheme.spacingSm),
                            Text(
              '${widget.productCount} items',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutral500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXs),
                        Row(
                  children: [
            Icon(
              Icons.monetization_on_rounded,
              size: 16,
              color: AppTheme.successColor,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              '\$${widget.totalPrice.toStringAsFixed(2)}',
              style: AppTheme.titleSmall.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
                            ),
                          ],
                        ),
                      ],
    );
  }

  Widget _buildStatusBadge() {
    final status = widget.orderStatus.toLowerCase();
    Color backgroundColor;
    Color textColor = Colors.white;
    
    switch (status) {
      case 'pending':
        backgroundColor = AppTheme.warningColor;
        break;
      case 'processing':
        backgroundColor = AppTheme.infoColor;
        break;
      case 'shipped':
        backgroundColor = AppTheme.secondaryColor;
        break;
      case 'delivered':
        backgroundColor = AppTheme.successColor;
        break;
      case 'cancelled':
        backgroundColor = AppTheme.errorColor;
        break;
      default:
        backgroundColor = AppTheme.neutral400;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Text(
        widget.orderStatus.toUpperCase(),
        style: AppTheme.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.visibility_rounded,
          gradient: AppTheme.primaryGradient,
          onTap: () => _viewOrderDetails(),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        PopupMenuButton<String>(
          onSelected: (value) => _updateOrderStatus(value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Pending', child: Text('Pending')),
            const PopupMenuItem(value: 'Processing', child: Text('Processing')),
            const PopupMenuItem(value: 'Shipped', child: Text('Shipped')),
            const PopupMenuItem(value: 'Delivered', child: Text('Delivered')),
            const PopupMenuItem(value: 'Cancelled', child: Text('Cancelled')),
          ],
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.secondaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              boxShadow: AppTheme.shadowSm,
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 18,
            ),
                            ),
                          ),
                        ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  LinearGradient _getStatusGradient() {
    final status = widget.orderStatus.toLowerCase();
    switch (status) {
      case 'pending':
        return AppTheme.warningGradient;
      case 'processing':
        return LinearGradient(
          colors: [AppTheme.infoColor, AppTheme.infoColor.withOpacity(0.8)],
        );
      case 'shipped':
        return AppTheme.secondaryGradient;
      case 'delivered':
        return AppTheme.successGradient;
      case 'cancelled':
        return AppTheme.errorGradient;
      default:
        return LinearGradient(
          colors: [AppTheme.neutral400, AppTheme.neutral500],
        );
    }
  }

  void _viewOrderDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
                              title: Text(
          'Order Details',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
            Text('Order ID: ${widget.orderId}'),
            Text('Customer: ${widget.userName}'),
            Text('Status: ${widget.orderStatus}'),
            Text('Total: \$${widget.totalPrice.toStringAsFixed(2)}'),
            Text('Items: ${widget.productCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(widget.orderId)
          .update({'status': newStatus});
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        GlobalMethods.errorDialog(
          subtitle: error.toString(), 
          context: context
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
