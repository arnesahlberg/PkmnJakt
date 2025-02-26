import 'package:flutter/material.dart';

Future<Map<String, String>?> promptForUserCredentials(
  BuildContext context,
  String scannedId,
) async {
  String username = "";
  String password = "";
  String confirm = "";
  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      // Enkel AlertDialog utan StatefulBuilder.
      return AlertDialog(
        title: Text("Registrera ny användare\n(ID: $scannedId)"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(labelText: "Namn att visa"),
                onChanged: (value) => username = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Lösenord"),
                obscureText: true,
                onChanged: (value) => password = value,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Bekräfta lösenord",
                ),
                obscureText: true,
                onChanged: (value) => confirm = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Avbryt"),
          ),
          ElevatedButton(
            onPressed: () {
              if (username.isNotEmpty &&
                  password.isNotEmpty &&
                  password == confirm) {
                Navigator.pop(context, {
                  'username': username,
                  'password': password,
                  'confirm': confirm,
                });
              }
            },
            child: const Text("Skapa användare"),
          ),
        ],
      );
    },
  );
}
