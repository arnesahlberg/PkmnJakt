import 'package:flutter/material.dart';
import 'package:pkmn_gui/api_calls.dart';
import 'package:provider/provider.dart';
import '../../main.dart'; // import UserSession from main.dart

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton; // new parameter
  final String? backRoute; // new parameter

  const CommonAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.backRoute,
  });

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    return AppBar(
      // Conditionally show a back button
      automaticallyImplyLeading: false,
      leading:
          showBackButton
              ? BackButton(
                onPressed: () {
                  if (backRoute != null) {
                    Navigator.pushReplacementNamed(context, backRoute!);
                  } else {
                    Navigator.pop(context);
                  }
                },
              )
              : null,
      title: Text(title, style: const TextStyle(fontFamily: 'PixelFontTitle')),
      // Added a gradient background
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.blue, Colors.yellow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        if (session.isLoggedIn)
          FutureBuilder<bool>(
            future: AdminApiService.amIAdmin(session.token!),
            builder: (context, snapshot) {
              final menuItems = <PopupMenuEntry<String>>[
                const PopupMenuItem(value: 'profile', child: Text('Profil')),
              ];
              if (snapshot.hasData && snapshot.data == true) {
                menuItems.add(
                  const PopupMenuItem(
                    value: 'admin',
                    child: Text('Admin-panel'),
                  ),
                );
              }
              menuItems.add(
                const PopupMenuItem(value: 'logout', child: Text('Logga ut')),
              );
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.pushNamed(context, '/profile');
                  } else if (value == 'admin') {
                    Navigator.pushNamed(context, '/admin');
                  } else if (value == 'logout') {
                    session.logout();
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
                itemBuilder: (context) => menuItems,
              );
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
