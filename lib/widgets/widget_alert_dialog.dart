import 'package:flutter/material.dart';

void showAlertDialog(BuildContext context, String title, String message,
    String confirmButtonText) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            child: Text(confirmButtonText),
          ),
        ),
      ],
    ),
  );
}
