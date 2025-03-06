import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;
  const UserDetailScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder: in a real app, fetch and display details for userId (e.g., pokemon caught, timestamps)
    return Scaffold(
      appBar: AppBar(title: Text('User Detail: $userId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Detailed information will be displayed here.'),
            Text('User ID: $userId'),
            // ...additional user info...
          ],
        ),
      ),
    );
  }
}
