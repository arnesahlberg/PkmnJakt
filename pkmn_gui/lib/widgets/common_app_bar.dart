import 'package:flutter/material.dart';
import 'package:pkmn_gui/api_calls.dart';
import 'package:pkmn_gui/constants.dart';
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
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
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
        style: TextStyle(
          fontFamily: 'PixelFontTitle',
          shadows: AppShadows.titleShadow,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryRed,
          border: Border(
            bottom: BorderSide(
              color: AppColors.secondaryRed,
              width: UIConstants.borderWidth3,
            ),
          ),
        ),
      ),
      actions: [
        if (session.isLoggedIn)
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.secondaryRed,
                width: UIConstants.borderWidth2,
              ),
              borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
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
                        borderRadius: BorderRadius.circular(
                          UIConstants.borderRadius8,
                        ),
                        side: AppBorderStyles.primaryBorder,
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
