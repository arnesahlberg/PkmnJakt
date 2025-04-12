import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'delete_user_popup.dart';
import 'reset_user_password_popup.dart';
import 'promote_user_popup.dart';
import 'demote_user_popup.dart';
import '../main.dart';

class EditUserDialog extends StatelessWidget {
  final String userId;
  final String userName;
  final bool userIsAdmin;
  final VoidCallback? onUserUpdated;

  const EditUserDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.userIsAdmin,
    this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF992109), width: 2),
      ),
      title: Text(
        'Hantera användare: $userId',
        style: const TextStyle(
          color: Colors.black87,
          fontFamily: 'PixelFontTitle',
          fontSize: 20,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Namn: $userName',
              style: const TextStyle(color: Colors.black87),
            ),
            subtitle: Text(
              userIsAdmin ? 'Admin' : 'Användare',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder:
                        (context) => ResetUserPasswordDialog(userId: userId),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE3350D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Återställ lösenord'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => DeleteUserDialog(
                          userId: userId,
                          onDeleted: onUserUpdated,
                        ),
                  );
                  if (result == true) {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Radera användare'),
              ),
            ],
          ),
          if (!userIsAdmin) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder:
                      (context) => PromoteUserDialog(
                        userId: userId,
                        isMainAdmin: false,
                        onUserUpdated: onUserUpdated,
                      ),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE3350D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Gör till administratör'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF992109)),
          child: const Text('Stäng'),
        ),
      ],
    );
  }
}
