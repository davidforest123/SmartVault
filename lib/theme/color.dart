import 'package:flutter/material.dart';

// toolbar color settings
extension CustomColorScheme on ColorScheme {
  Color get foregroundText => brightness == Brightness.light
      ? Colors.black // cursor color and text color
      : Colors.white60;

  Color get cardColor => brightness == Brightness.light
      ? Colors.white // TextFormField background color
      : Colors.white60;

  Color get barIconColor => brightness == Brightness.light
      ? Colors.black54 // button filled color
      : Colors.white60;

  Color get barColor => brightness == Brightness.light
      ? const Color.fromARGB(255, 255, 251, 254) // toolbar background color
      : Colors.white60;
}
