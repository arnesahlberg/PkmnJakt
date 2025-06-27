import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import 'pokedex_container.dart';
import '../screens/user_statistics_screen.dart';
import '../api_calls.dart';

class HighscoreList extends StatefulWidget {
  final List<dynamic> highscores;
  final String title;
  final bool showContainer;
  final bool clickable;
  final bool showFirstPlacesIcons;
  final bool linkToHighscorePage;
  final int currentPage;
  final bool hasActiveSearch;

  const HighscoreList({
    super.key,
    required this.highscores,
    this.title = "Global Highscore",
    this.showContainer = true,
    this.clickable = false,
    this.showFirstPlacesIcons = false,
    this.linkToHighscorePage = false,
    this.currentPage = 1,
    this.hasActiveSearch = false,
  });

  @override
  State<HighscoreList> createState() => _HighscoreListState();
}

class _HighscoreListState extends State<HighscoreList> {
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(HighscoreList oldWidget) {
    super.didUpdateWidget(oldWidget);
  }


  bool _hasDuplicateScore(dynamic currentScore) {
    return widget.highscores.where((s) => s['score'] == currentScore['score']).length >
        1;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'PixelFontTitle',
                  fontSize: 20,
                  color: Color(0xFFE3350D),
                ),
              ),
              if (widget.linkToHighscorePage)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/highscore');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Visa alla →",
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 14,
                      color: Color(0xFF992109),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (widget.highscores.isEmpty)
          const Text("Ingen highscore data än.")
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.highscores.length,
            itemBuilder: (context, index) {
              final score = widget.highscores[index];

              // build the normal row
              Widget row = Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _pressedIndex == index 
                      ? Colors.grey[100] 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF992109), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      if (widget.showFirstPlacesIcons && 
                          widget.currentPage == 1 && 
                          !widget.hasActiveSearch && 
                          index < 3) ...[
                        Icon(
                          Icons.emoji_events,
                          color:
                              index == 0
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    score['name'],
                                    style: const TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "ID: ${score['id']}",
                              style: const TextStyle(
                                fontFamily: 'PixelFont',
                                fontSize: 10,
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
                            DateFormat(
                              'dd/MM HH:mm:ss',
                            ).format(DateTime.parse(score['latest_found'])),
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
                      if (widget.clickable) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF992109),
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );

              // if clickable, wrap with tap navigation
              if (widget.clickable) {
                return GestureDetector(
                  onTapDown: (_) {
                    setState(() {
                      _pressedIndex = index;
                    });
                  },
                  onTapUp: (_) {
                    setState(() {
                      _pressedIndex = null;
                    });
                  },
                  onTapCancel: () {
                    setState(() {
                      _pressedIndex = null;
                    });
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => UserStatisticsScreen(
                              userId: score['id'].toString(),
                              userName: score['name'],
                            ),
                      ),
                    );
                  },
                  child: row,
                );
              }

              return row;
            },
          ),
      ],
    );

    if (widget.showContainer) {
      return PokedexContainer(child: content);
    } else {
      return content;
    }
  }
}
