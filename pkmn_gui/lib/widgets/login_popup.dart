import 'package:flutter/material.dart';

Future<String?> promptForPassword(BuildContext context) async {
  String password = "";
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Enter Password"),
        content: TextField(
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Password"),
          onChanged: (value) {
            password = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, password),
            child: const Text("Submit"),
          ),
        ],
      );
    },
  );
}
