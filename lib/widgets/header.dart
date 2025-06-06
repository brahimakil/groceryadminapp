import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/themes/app_theme.dart';
import 'package:grocery_admin_panel/providers/dark_theme_provider.dart';
import 'package:provider/provider.dart';

import '../responsive.dart';

class Header extends StatefulWidget {
  const Header({
    Key? key,
    required this.title,
    required this.fct,
    this.showSearchField = true,
  }) : super(key: key);
  
  final String title;
  final Function fct;
  final bool showSearchField;

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).darkTheme;
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppTheme.spacingMd : AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.neutral700 : AppTheme.neutral200,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Mobile Menu Button
                if (!Responsive.isDesktop(context))
                  Container(
                    margin: const EdgeInsets.only(right: AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.fct(),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          child: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Title Section
                Expanded(
                  flex: isMobile ? 2 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: (isMobile 
                          ? AppTheme.headlineSmall 
                          : AppTheme.headlineMedium
                        ).copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          _getSubtitle(),
                          style: AppTheme.bodySmall.copyWith(
                            color: isDark ? AppTheme.neutral400 : AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Search Field
                if (widget.showSearchField && !isMobile)
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                      child: _buildSearchField(isDark),
                    ),
                  ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Button for Mobile
                    if (widget.showSearchField && isMobile)
                      _buildActionButton(
                        icon: Icons.search_rounded,
                        onTap: () => _showMobileSearch(context),
                        gradient: AppTheme.secondaryGradient,
                      ),

                    if (!isMobile) const SizedBox(width: AppTheme.spacingSm),

                    // Notifications
                    _buildActionButton(
                      icon: Icons.notifications_rounded,
                      onTap: () => _showNotifications(context),
                      gradient: AppTheme.warningGradient,
                      badge: '3',
                    ),

                    const SizedBox(width: AppTheme.spacingSm),

                    // Profile
                    _buildProfileSection(isDark, isMobile),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isSearchFocused = focused;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.neutral700 : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: _isSearchFocused 
              ? AppTheme.primaryColor 
              : (isDark ? AppTheme.neutral600 : AppTheme.neutral200),
            width: _isSearchFocused ? 2 : 1,
          ),
          boxShadow: _isSearchFocused ? AppTheme.shadowSm : null,
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products, orders, categories...',
            hintStyle: AppTheme.bodyMedium.copyWith(
              color: isDark ? AppTheme.neutral400 : AppTheme.neutral500,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Icon(
                Icons.search_rounded,
                color: _isSearchFocused 
                  ? AppTheme.primaryColor 
                  : (isDark ? AppTheme.neutral400 : AppTheme.neutral500),
                size: 20,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? AppTheme.neutral400 : AppTheme.neutral500,
                    size: 20,
                  ),
                )
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingMd,
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required LinearGradient gradient,
    String? badge,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.errorColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badge,
                style: AppTheme.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildProfileSection(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spacingSm : AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.neutral700 : AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppTheme.neutral600 : AppTheme.neutral200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isMobile ? 32 : 36,
            height: isMobile ? 32 : 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.shadowSm,
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: isMobile ? 16 : 18,
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: AppTheme.spacingSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.successColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? AppTheme.neutral400 : AppTheme.neutral500,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  String _getSubtitle() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    
    return '$greeting! Here\'s what\'s happening today.';
  }

  void _showMobileSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radius2Xl),
            topRight: Radius.circular(AppTheme.radius2Xl),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral300,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildSearchField(Provider.of<DarkThemeProvider>(context).darkTheme),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: const Center(
                  child: Text('Search functionality coming soon...'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radius2Xl),
            topRight: Radius.circular(AppTheme.radius2Xl),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral300,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Notifications',
                    style: AppTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: const Center(
                  child: Text('No new notifications'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}