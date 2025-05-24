import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dark_theme_provider.dart';


class Utils {
  BuildContext context;
  Utils(this.context);

  bool get getTheme => Provider.of<DarkThemeProvider>(context).darkTheme;
  Color get color => Theme.of(context).textTheme.bodyLarge!.color!;
  Size get getScreenSize => MediaQuery.of(context).size; 
}
