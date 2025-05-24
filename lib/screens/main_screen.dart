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
      drawer: const SideMenu(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // We want this side menu only for large screen
            if (Responsive.isDesktop(context))
              const Expanded(
                // default flex = 1
                // and it takes 1/6 part of the screen
                child: SideMenu(),
              ),
            const Expanded(
              // It takes 5/6 part of the screen
              flex: 5,
              child: DashboardScreen(),
            ),
          ],
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
