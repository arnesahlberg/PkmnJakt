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
    this.userIsAdmin = false,
    this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final currentIsMainAdmin =
        Provider.of<UserSession>(context, listen: false).userId == 'admin';
    return AlertDialog(
      title: Text('Redigera användare: $userId'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Namn: $userName'),
          const SizedBox(height: 20),
          // Återställ lösenord
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => ResetUserPasswordDialog(userId: userId),
              );
            },
            child: const Text('Återställ lösenord'),
          ),
          const SizedBox(height: 10),
          userIsAdmin
              ? ElevatedButton(
                onPressed:
                    currentIsMainAdmin
                        ? () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder:
                                (context) => DemoteUserDialog(
                                  userId: userId,
                                  onUserUpdated: onUserUpdated,
                                ),
                          );
                        }
                        : null,
                child: const Text('Gör till icke administratör'),
              )
              : ElevatedButton(
                onPressed: () {
                  final isMainAdmin =
                      Provider.of<UserSession>(context, listen: false).userId ==
                      'admin';
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder:
                        (context) => PromoteUserDialog(
                          userId: userId,
                          isMainAdmin: isMainAdmin,
                          onUserUpdated: onUserUpdated,
                        ),
                  );
                },
                child: const Text('Gör till administratör'),
              ),
          const SizedBox(height: 10),
          // Radera användare
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder:
                    (context) => DeleteUserDialog(
                      userId: userId,
                      onDeleted: onUserUpdated,
                    ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Radera användare'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Stäng'),
        ),
      ],
    );
  }
}
