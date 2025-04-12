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
      automaticallyImplyLeading: false,
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (backRoute != null) {
                    Navigator.pushReplacementNamed(context, backRoute!);
                  } else {
                    Navigator.pop(context);
                  }
                },
              )
              : null,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'PixelFontTitle',
          shadows: [
            Shadow(
              offset: Offset(1.0, 1.0),
              blurRadius: 3.0,
              color: Color(0xFF992109),
            ),
          ],
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE3350D),
          border: Border(
            bottom: BorderSide(color: const Color(0xFF992109), width: 3.0),
          ),
        ),
      ),
      actions: [
        if (session.isLoggedIn)
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF992109), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FutureBuilder<bool>(
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
                return Theme(
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: PopupMenuThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: Color(0xFF992109),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  child: PopupMenuButton<String>(
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
                    icon: const Icon(Icons.menu, color: Colors.white),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
