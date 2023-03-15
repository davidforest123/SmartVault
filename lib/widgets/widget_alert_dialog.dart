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

Future<dynamic> showChoiceDialog(
    BuildContext context, String title, String message, List<String> choices) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: List.generate(
        choices.length,
        (index) => ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop(choices[index]);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            child: Text(choices[index]),
          ),
        ),
      ),
    ),
  );
}
