import 'package:flutter/material.dart';
import '../constants.dart';

// popup for changing user name
Future<String?> changeUserNamePopup(BuildContext context) async {
  String name = "";
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadius12),
          side: AppBorderStyles.primaryBorder,
        ),
        title: const Text(
          "Ange nytt användarnamn",
          style: AppTextStyles.titleMedium,
        ),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.black87),
          decoration: AppInputDecorations.defaultInputDecoration(
            "Användarnamn",
          ),
          onChanged: (value) {
            name = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondaryRed,
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
            style: AppButtonStyles.primaryButtonStyle,
            child: const Text("OK", style: AppTextStyles.buttonText),
          ),
        ],
      );
    },
  );
}
