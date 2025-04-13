import 'package:flutter/material.dart';

class PokedexButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final double width;
  final double height;

  const PokedexButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.width = double.infinity,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF992109).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF992109), width: 2),
          ),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 16,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 2.0,
                color: Color(0xFF992109),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
