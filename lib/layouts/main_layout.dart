import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/widgets/side_menu.dart';
import 'package:grocery_admin_panel/widgets/header.dart';
import 'package:grocery_admin_panel/responsive.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const MainLayout({
    Key? key,
    required this.child,
    required this.title,
    required this.scaffoldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
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
                    title: title,
                    fct: () {
                      scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 