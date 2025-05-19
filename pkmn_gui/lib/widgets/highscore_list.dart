import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import 'pokedex_container.dart';

class HighscoreList extends StatelessWidget {
  final List<dynamic> highscores;
  final String title;
  final bool showContainer;

  const HighscoreList({
    super.key,
    required this.highscores,
    this.title = "Global Highscore",
    this.showContainer = true,
  });

  bool _hasDuplicateScore(dynamic currentScore) {
    return highscores.where((s) => s['score'] == currentScore['score']).length > 1;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PixelFontTitle',
            fontSize: 20,
            color: Color(0xFFE3350D),
          ),
        ),
        const SizedBox(height: 16),
        if (highscores.isEmpty)
          const Text("Ingen highscore data än.")
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: highscores.length,
            itemBuilder: (context, index) {
              final score = highscores[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF992109),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (index < 3) ...[
                      Icon(
                        Icons.emoji_events,
                        color: index == 0
                            ? Colors.amber
                            : index == 1
                            ? Colors.grey[400]
                            : Colors.brown[300],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Text(
                            "${score['name']} ",
                            style: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "(ID: ${score['id']})",
                            style: const TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasDuplicateScore(score)) ...[
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormat('dd/MM HH:mm:ss').format(
                            DateTime.parse(score['latest_found']),
                          ),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 10,
                            color: Color(0xFF992109),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Expanded(flex: 2, child: SizedBox()),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3350D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${score['score']}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PixelFont',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );

    if (showContainer) {
      return PokedexContainer(child: content);
    } else {
      return content;
    }
  }
}
