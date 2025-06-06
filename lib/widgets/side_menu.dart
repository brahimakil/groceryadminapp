import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/inner_screens/all_orders_screen.dart';
import 'package:grocery_admin_panel/inner_screens/all_products.dart';
import 'package:grocery_admin_panel/providers/dark_theme_provider.dart';
import 'package:grocery_admin_panel/themes/app_theme.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

import '../screens/main_screen.dart';
import '../inner_screens/categories_screen.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedRoute = '/';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Get current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context)?.settings.name ?? '/';
      setState(() {
        _selectedRoute = route;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context);
    final isDark = themeState.darkTheme;

    return Container(
      width: 280,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark 
            ? [
                AppTheme.neutral800,
                AppTheme.neutral900,
              ]
            : [
                Colors.white,
                AppTheme.neutral50,
              ],
        ),
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.neutral700 : AppTheme.neutral200,
            width: 1,
          ),
        ),
        boxShadow: AppTheme.shadowLg,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Beautiful Header - Fixed
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radius2Xl),
                  bottomRight: Radius.circular(AppTheme.radius2Xl),
                ),
              ),
              child: Column(
                children: [
                  // Logo Container
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radius2Xl),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'Grocery Admin',
                    style: AppTheme.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      'Dashboard Panel',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                        child: Text(
                          'NAVIGATION',
                          style: AppTheme.labelSmall.copyWith(
                            color: isDark ? AppTheme.neutral400 : AppTheme.neutral500,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      
                      // Menu Items
                      _buildMenuItem(
                        icon: Icons.dashboard_rounded,
                        title: 'Dashboard',
                        isSelected: _selectedRoute == '/' || _selectedRoute.isEmpty,
                        onTap: () => _navigateTo(context, const MainScreen(), '/'),
                        gradient: AppTheme.primaryGradient,
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.inventory_2_rounded,
                        title: 'Products',
                        isSelected: _selectedRoute == '/products',
                        onTap: () => _navigateTo(context, const AllProductsScreen(), '/products'),
                        gradient: AppTheme.secondaryGradient,
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.shopping_bag_rounded,
                        title: 'Orders',
                        isSelected: _selectedRoute == '/orders',
                        onTap: () => _navigateTo(context, const AllOrdersScreen(), '/orders'),
                        gradient: AppTheme.warningGradient,
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.category_rounded,
                        title: 'Categories',
                        isSelected: _selectedRoute == '/categories',
                        onTap: () => _navigateTo(context, const CategoriesScreen(), '/categories'),
                        gradient: AppTheme.accentGradient,
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXl),
                      
                      // Settings Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                        child: Text(
                          'SETTINGS',
                          style: AppTheme.labelSmall.copyWith(
                            color: isDark ? AppTheme.neutral400 : AppTheme.neutral500,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      
                      // Theme Toggle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.neutral700 : AppTheme.neutral100,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: isDark ? AppTheme.neutral600 : AppTheme.neutral200,
                          ),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Dark Mode',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            isDark ? 'Switch to light theme' : 'Switch to dark theme',
                            style: AppTheme.bodySmall.copyWith(
                              color: isDark ? AppTheme.neutral400 : AppTheme.neutral500,
                            ),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(AppTheme.spacingSm),
                            decoration: BoxDecoration(
                              gradient: isDark ? AppTheme.primaryGradient : AppTheme.warningGradient,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          value: isDark,
                          onChanged: (value) {
                            themeState.toggleTheme(value);
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXl),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer - Fixed at bottom
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.neutral800 : AppTheme.neutral100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radius2Xl),
                  topRight: Radius.circular(AppTheme.radius2Xl),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor,
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Admin User',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'admin@grocery.com',
                          style: AppTheme.bodySmall.copyWith(
                            color: isDark ? AppTheme.neutral400 : AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.settings_rounded,
                      color: isDark ? AppTheme.neutral400 : AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required LinearGradient gradient,
  }) {
    final isDark = Provider.of<DarkThemeProvider>(context).darkTheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      decoration: BoxDecoration(
        gradient: isSelected ? gradient : null,
        color: isSelected 
          ? null 
          : (isDark ? AppTheme.neutral700.withOpacity(0.3) : Colors.transparent),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: isSelected ? AppTheme.shadowMd : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingMd,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? Colors.white.withOpacity(0.2)
                      : (isDark ? AppTheme.neutral600 : AppTheme.neutral200),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
          icon,
                    size: 20,
                    color: isSelected 
                      ? Colors.white
                      : (isDark ? AppTheme.neutral300 : AppTheme.neutral600),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.bodyMedium.copyWith(
                      color: isSelected 
                        ? Colors.white
                        : (isDark ? AppTheme.neutral200 : AppTheme.neutral700),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen, String route) {
    setState(() {
      _selectedRoute = route;
    });
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        settings: RouteSettings(name: route),
      ),
    );
  }
}
