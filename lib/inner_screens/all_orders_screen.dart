import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grocery_admin_panel/themes/app_theme.dart';

import '../controllers/MenuController.dart' as grocery;
import '../responsive.dart';
import '../widgets/header.dart';
import '../widgets/orders_list.dart';
import '../widgets/side_menu.dart';
import '../consts/constants.dart';

class AllOrdersScreen extends StatelessWidget {
  const AllOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: context.read<grocery.GroceryMenuController>().getOrdersScaffoldKey,
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
                          context.read<grocery.GroceryMenuController>().controlAllOrder();
                        },
                        title: 'All Orders',
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
                                  AppTheme.warningColor,
                                  AppTheme.warningColor.withOpacity(0.8),
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
                                        'Order Management',
                                        style: AppTheme.headlineLarge.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: AppTheme.spacingSm),
                                      Text(
                                        'Track and manage all customer orders',
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
                                    Icons.shopping_bag_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                          
                          // Orders List
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
                                      'All Orders',
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
                                        color: AppTheme.successColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                      child: Text(
                                        'Real-time',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingLg),
                                const OrdersList(isInDashboard: false),
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
