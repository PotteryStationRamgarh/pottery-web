import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// LogoPlaceholder — circular grey logo shown until real logo is ready.
/// When logo is ready — swap this widget with Image.asset('assets/images/logo.png')
class LogoPlaceholder extends StatelessWidget {
  final double size;

  const LogoPlaceholder({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.greyPlaceholder,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.divider,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.question_mark_rounded,
        size: size * 0.45,
        color: AppTheme.white,
      ),
    );
  }
}