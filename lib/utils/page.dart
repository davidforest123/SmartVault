import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Close current screen and come back to previous screen.
/// Mostly, Navigator.pop(context) should do the work.
/// However, if you are at the entry screen (the first screen of the app and
///    this screen has no parent screen/previous screen), Navigator.pop(context)
///    will return you to a black screen.
///    In this case, we have to use SystemNavigator.pop().
/// Don't use SystemNavigator.pop() for iOS, Apple says that the application should not exit itself.
void utilBackToPreviousPage(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  } else {
    SystemNavigator.pop();
  }
}
