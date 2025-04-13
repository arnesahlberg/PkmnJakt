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
    // Check if the logged-in user is the main admin account
    final userSession = Provider.of<UserSession>(context, listen: false);
    final bool isMainAdmin = userSession.userId == 'admin';

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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            // Reset password button
            ElevatedButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const ResetUserPasswordDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE3350D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Återställ lösenord'),
            ),
            const SizedBox(height: 8),

            // Only show delete user button for non-admins or if main admin is logged in
            if (!userIsAdmin || (userIsAdmin && isMainAdmin)) ...[
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text('Radera användare'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Promote to admin button (only for non-admin users)
            if (!userIsAdmin) ...[
              ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder:
                        (context) => PromoteUserDialog(
                          userId: userId,
                          isMainAdmin: isMainAdmin,
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

            // Demote from admin button (only if user is admin and main admin is logged in)
            if (userIsAdmin && isMainAdmin) ...[
              ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder:
                        (context) => DemoteUserDialog(
                          userId: userId,
                          onUserUpdated: onUserUpdated,
                        ),
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE3350D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ta bort administratörsrättigheter'),
              ),
            ],
          ],
        ),
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
