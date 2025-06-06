import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/screens/main_screen.dart';
import 'package:grocery_admin_panel/themes/app_theme.dart';
import 'package:provider/provider.dart';

import 'controllers/MenuController.dart' as grocery;
import 'inner_screens/add_prod.dart';
import 'providers/dark_theme_provider.dart';
import 'firebase_options.dart';
import 'inner_screens/categories_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late DarkThemeProvider themeChangeProvider;

  @override
  void initState() {
    themeChangeProvider = DarkThemeProvider();
    _initializeTheme();
    super.initState();
  }

  Future<void> _initializeTheme() async {
    await themeChangeProvider.loadThemePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => grocery.GroceryMenuController(),
        ),
        ChangeNotifierProvider(
          create: (_) => themeChangeProvider,
        ),
      ],
      child: Consumer<DarkThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Grocery Admin Panel',
            theme: themeProvider.darkTheme ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const _AppLoader(),
            routes: {
              UploadProductForm.routeName: (context) => const UploadProductForm(),
              CategoriesScreen.routeName: (context) => const CategoriesScreen(),
            },
          );
        },
      ),
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader({Key? key}) : super(key: key);

  @override
  __AppLoaderState createState() => __AppLoaderState();
}

class __AppLoaderState extends State<_AppLoader> {
  @override
  void initState() {
    super.initState();
    _loadThemeAndNavigate();
  }

  Future<void> _loadThemeAndNavigate() async {
    final themeProvider = Provider.of<DarkThemeProvider>(context, listen: false);
    await themeProvider.loadThemePreferences();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: AppTheme.shadowLg,
              ),
              child: Icon(
                Icons.store,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              'Grocery Admin Panel',
              style: AppTheme.headingLarge.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
