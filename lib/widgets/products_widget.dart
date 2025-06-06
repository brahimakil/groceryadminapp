import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../inner_screens/edit_prod.dart';
import '../services/global_method.dart';
import '../services/utils.dart';
import 'text_widget.dart';
import 'package:grocery_admin_panel/themes/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/dark_theme_provider.dart';
import '../responsive.dart';

class ProductWidget extends StatefulWidget {
  const ProductWidget({
    Key? key,
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.isOnSale,
    required this.salePrice,
    required this.categoryName,
    required this.description,
    required this.nutrients,
    required this.calories,
  }) : super(key: key);

  final String id, title, price, imageUrl, categoryName, description, nutrients;
  final bool isOnSale;
  final double salePrice;
  final int calories;

  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).darkTheme;
    final isMobile = Responsive.isMobile(context);
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: _isHovered 
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : (isDark ? AppTheme.neutral700 : AppTheme.neutral200),
                  width: _isHovered ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppTheme.neutral900).withOpacity(0.1),
                    blurRadius: _elevationAnimation.value + 4,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.neutral100,
                                  AppTheme.neutral50,
                                ],
                              ),
                            ),
                            child: _buildProductImage(),
                          ),
                          
                          // Sale Badge
                          if (widget.isOnSale)
                            Positioned(
                              top: AppTheme.spacingSm,
                              left: AppTheme.spacingSm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSm,
                                  vertical: AppTheme.spacingXs,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.errorGradient,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  boxShadow: AppTheme.shadowSm,
                                ),
                                child: Text(
                                  'SALE',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          
                          // Action Buttons
                          Positioned(
                            top: AppTheme.spacingSm,
                            right: AppTheme.spacingSm,
                            child: Column(
                              children: [
                                _buildActionButton(
                                  icon: Icons.edit_rounded,
                                  gradient: AppTheme.primaryGradient,
                                  onTap: () => _editProduct(context),
                                ),
                                const SizedBox(height: AppTheme.spacingSm),
                                _buildActionButton(
                                  icon: Icons.delete_rounded,
                                  gradient: AppTheme.errorGradient,
                                  onTap: () => _deleteProduct(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content Section - FIXED OVERFLOW
                    Container(
                      height: isMobile ? 100 : 120, // Fixed height to prevent overflow
                      padding: const EdgeInsets.all(AppTheme.spacingSm), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSm,
                              vertical: 2, // Reduced padding
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              widget.categoryName,
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10, // Reduced font size
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingXs), // Reduced spacing
                          
                          // Product Title
                          Expanded(
                            child: Text(
                              widget.title,
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 12 : 14, // Responsive font size
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingXs), // Reduced spacing
                          
                          // Price Section
                          Row(
                            children: [
                              if (widget.isOnSale) ...[
                                Flexible(
                                  child: Text(
                                    '\$${widget.salePrice.toStringAsFixed(2)}',
                                    style: AppTheme.titleMedium.copyWith(
                                      color: AppTheme.errorColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 12 : 14, // Responsive font size
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingXs),
                                Flexible(
                                  child: Text(
                                    '\$${widget.price}',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.neutral400,
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: isMobile ? 10 : 12, // Responsive font size
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else ...[
                    Flexible(
                                  child: Text(
                                    '\$${widget.price}',
                                    style: AppTheme.titleMedium.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 12 : 14, // Responsive font size
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingXs,
                                  vertical: 2, // Reduced padding
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.infoColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                                ),
                                child: Text(
                                  '${widget.calories} cal',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.infoColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 9, // Reduced font size
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildProductImage() {
    if (widget.imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }
    
    try {
      return Image.memory(
        base64Decode(widget.imageUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, error, stackTrace) {
          return _buildNetworkImage();
        },
      );
    } catch (e) {
      return _buildNetworkImage();
    }
  }

  Widget _buildNetworkImage() {
      return Image.network(
      widget.imageUrl,
        fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
        errorBuilder: (ctx, error, stackTrace) {
        return _buildPlaceholderImage();
        },
      );
    }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.neutral100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            size: 48,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'No Image',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
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
            size: 16,
          ),
        ),
      ),
    );
  }

  void _editProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          id: widget.id,
          title: widget.title,
          price: widget.price,
          categoryName: widget.categoryName,
          imageUrl: widget.imageUrl,
          description: widget.description,
          nutrients: widget.nutrients,
          calories: widget.calories,
        ),
      ),
    );
  }

  void _deleteProduct(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Delete Product',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.title}"? This action cannot be undone.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Add delete functionality here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

final Uint8List kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82
]); // Tiny transparent PNG
