import 'package:flutter/material.dart';
import 'delete_user_popup.dart';
import 'reset_user_password_popup.dart';

class EditUserDialog extends StatelessWidget {
  final String userId;
  final String userName;
  final VoidCallback? onUserUpdated; // new

  const EditUserDialog({
    Key? key,
    required this.userId,
    required this.userName,
    this.onUserUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Redigera användare: $userId'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Namn: $userName'),
          const SizedBox(height: 20),
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder:
                    (context) => DeleteUserDialog(
                      userId: userId,
                      onDeleted: onUserUpdated, // pass callback
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
