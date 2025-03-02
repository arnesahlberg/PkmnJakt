import 'package:flutter/material.dart';

Future<String?> promptForPassword(BuildContext context) async {
  String password = "";
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Ange lösenord"),
        content: TextField(
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Lösenord"),
          onChanged: (value) {
            password = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Avbryt"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, password),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}
