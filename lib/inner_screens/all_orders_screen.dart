import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/widgets/orders_list.dart';
import 'package:provider/provider.dart';

import '../controllers/MenuController.dart' as grocery;
import '../responsive.dart';
import '../consts/constants.dart'; // Add this line
import '../services/utils.dart';
import '../widgets/grid_products.dart';
import '../widgets/header.dart';
import '../widgets/side_menu.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = Utils(context).getScreenSize;
    return Scaffold(
      key: context.read<grocery.GroceryMenuController>().getOrdersScaffoldKey,
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
            Expanded(
                // It takes 5/6 part of the screen
                flex: 5,
                child: SingleChildScrollView(
                  controller: ScrollController(),
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 25,
                      ),
                      Header(
                        fct: () {
                          context.read<grocery.GroceryMenuController>().controlAllOrder();
                        },
                        title: 'All Orders',
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const OrdersList(isInDashboard: false),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
