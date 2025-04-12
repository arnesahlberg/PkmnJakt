import 'package:flutter/material.dart';

// popup for changing user name
Future<String?> changeUserNamePopup(BuildContext context) async {
  String name = "";
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF992109), width: 2),
        ),
        title: const Text(
          "Ange nytt användarnamn",
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'PixelFontTitle',
            fontSize: 20,
          ),
        ),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: "Användarnamn",
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF992109), width: 2),
            ),
          ),
          onChanged: (value) {
            name = value;
          },
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
            onPressed:
                () => {
                  if (name.isEmpty)
                    {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Användarnamn får inte vara tomt"),
                          backgroundColor: Color(0xFFE3350D),
                        ),
                      ),
                    }
                  else
                    Navigator.pop(context, name),
                },
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
