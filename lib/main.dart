import 'package:flutter/material.dart';
import 'package:textvault/pages/pageChangePassword.dart';
import 'package:textvault/pages/pageDecryptFile.dart';
import 'package:textvault/pages/pageEditor.dart';
import 'package:textvault/pages/pageSetPassword.dart';
import 'package:textvault/pages/pageSettings.dart';
import 'package:textvault/theme/color.dart';

void main() {
  runApp(TextVaultApp());
}

// main application
class TextVaultApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Theme.of(context).colorScheme.barColor,
      ),
      title: 'TextVault',
      // Start the app with the "/" named route.
      initialRoute: '/',
      // When navigating to a route, build the corresponding page.
      routes: {
        '/': (context) => PageEditor(),
        '/pageChangePassword': (context) => PageChangePassword(),
        '/pageDecryptFile': (context) => PageDecryptFile(),
        '/pageEditor': (context) => PageEditor(),
        '/pageSetPassword': (context) => PageSetPassword(),
        '/pageSettings': (context) => PageSettings(),
      },
    );
  }
}
