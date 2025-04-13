import 'package:flutter/material.dart';
import '../constants.dart';

class PokedexContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool hasBorder;
  final Color? backgroundColor;

  const PokedexContainer({
    super.key,
    required this.child,
    this.padding,
    this.hasBorder = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: UIConstants.spacing8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.borderRadius12),
        border:
            hasBorder
                ? Border.all(
                  color: AppColors.secondaryRed,
                  width: UIConstants.borderWidth2,
                )
                : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          hasBorder ? UIConstants.borderRadius10 : UIConstants.borderRadius12,
        ),
        child: Container(
          padding: padding ?? const EdgeInsets.all(UIConstants.padding16),
          decoration:
              backgroundColor != null
                  ? BoxDecoration(color: backgroundColor)
                  : AppBoxDecorations.pokedexContainerDecoration,
          child: DefaultTextStyle(
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey.shade800,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
