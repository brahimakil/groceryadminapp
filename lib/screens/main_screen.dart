import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/controllers/MenuController.dart' as grocery;
import 'package:grocery_admin_panel/widgets/side_menu.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../responsive.dart';
import 'dashboard_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: context.read<grocery.GroceryMenuController>().getScaffoldKey,
      drawer: !Responsive.isDesktop(context) ? const SideMenu() : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar for desktop
                if (Responsive.isDesktop(context))
                  const SizedBox(
                    width: 280,
                    child: SideMenu(),
                  ),
                // Main content area
                Expanded(
                  child: Container(
                    height: constraints.maxHeight,
                    child: const DashboardScreen(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _ensureCategoriesCollection() async {
    final categoriesRef = FirebaseFirestore.instance.collection('categories');
    final snapshot = await categoriesRef.limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      // Create a default category if none exists
      await categoriesRef.add({
        'id': const Uuid().v4(),
        'name': 'Uncategorized',
        'createdAt': Timestamp.now(),
      });
    }
  }
}
