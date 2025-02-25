import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common_app_bar.dart';
import '../main.dart'; // for UserSession

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Stensund Pokemon-Jakt 2025!'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child:
              session.isLoggedIn
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Välkommen tillbaka, ${session.userName}!',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(fontSize: 20),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        child: const Text('Gå till startsidan'),
                      ),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Välkommen till Stensund Pokemon-Jakt 2025!',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Klicka på knappen nedan och scanna ditt deltagar-band för rikslägret.',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(fontSize: 20),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/scanner');
                        },
                        child: const Text('Logga in med bandet'),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
