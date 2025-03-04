import 'package:flutter/material.dart';

// popup for changing user name
Future<String?> changeUserNamePopup(BuildContext context) async {
  String name = "";
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Ange nytt användarnamn"),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Användarnamn",
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            name = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Avbryt"),
          ),
          ElevatedButton(
            onPressed:
                () => {
                  if (name.isEmpty)
                    {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Användarnamn får inte vara tomt"),
                        ),
                      ),
                    }
                  else
                    Navigator.pop(context, name),
                },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}
