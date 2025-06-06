import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grocery_admin_panel/themes/app_theme.dart';

import '../controllers/MenuController.dart' as grocery;
import '../responsive.dart';
import '../services/utils.dart';
import '../widgets/grid_products.dart';
import '../widgets/header.dart';
import '../widgets/side_menu.dart';
import '../consts/constants.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({Key? key}) : super(key: key);

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = Utils(context).getScreenSize;
    return Scaffold(
      key: context.read<grocery.GroceryMenuController>().getgridscaffoldKey,
      drawer: !Responsive.isDesktop(context) ? const SideMenu() : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              const Expanded(
                child: SideMenu(),
              ),
            Expanded(
              flex: 5,
                child: Column(
                  children: [
                    Header(
                      fct: () {
                        context.read<grocery.GroceryMenuController>().controlProductsMenu();
                      },
                      title: 'All Products',
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingLg),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              boxShadow: AppTheme.shadowSm,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Product Inventory',
                                        style: AppTheme.headingLarge.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: AppTheme.spacingSm),
                                      Text(
                                        'Manage your product catalog and inventory',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                          
                          // Products Grid
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingLg),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              border: Border.all(color: Theme.of(context).dividerColor),
                              boxShadow: AppTheme.shadowSm,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Products',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingMd,
                                        vertical: AppTheme.spacingSm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                      child: Text(
                                        'Live Data',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingLg),
                    Responsive(
                      mobile: ProductGridWidget(
                                    crossAxisCount: size.width < 650 ? 1 : 2,
                                    childAspectRatio: size.width < 650 ? 1.2 : 1.1,
                                    isInMain: false,
                                  ),
                                  tablet: ProductGridWidget(
                                    crossAxisCount: 3,
                                    childAspectRatio: 0.9,
                        isInMain: false,
                      ),
                      desktop: ProductGridWidget(
                                    crossAxisCount: size.width < 1400 ? 3 : 4,
                        childAspectRatio: size.width < 1400 ? 0.8 : 1.05,
                        isInMain: false,
                      ),
                    ),
                  ],
                ),
                          ),
                        ],
                      ),
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
}
