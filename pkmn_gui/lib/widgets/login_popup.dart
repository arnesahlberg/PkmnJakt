import 'package:flutter/material.dart';

Future<String?> promptForPassword(BuildContext context) async {
  String password = "";
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF992109), width: 2),
        ),
        backgroundColor: Colors.white,
        title: const Text(
          "Ange lösenord",
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'PixelFontTitle',
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Band scannat tidigare. Logga in för att fortsätta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Lösenord",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF992109),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                password = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF992109),
            ),
            child: const Text("Avbryt"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, password),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE3350D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF992109), width: 2),
              ),
            ),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}
