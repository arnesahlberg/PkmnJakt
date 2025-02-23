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
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Register New User\n(ID: $scannedId)"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: "Username"),
                    onChanged: (value) => username = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    onChanged: (value) => password = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
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
                child: const Text("Cancel"),
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
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );
    },
  );
}
