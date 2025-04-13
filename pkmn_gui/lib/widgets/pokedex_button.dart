import 'package:flutter/material.dart';
import '../constants.dart';

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
        borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
        boxShadow: AppShadows.containerShadow,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primaryRed,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.padding16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
            side: AppBorderStyles.primaryBorder,
          ),
        ),
        child: DefaultTextStyle(
          style: AppTextStyles.buttonText.copyWith(
            shadows: AppShadows.textShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
