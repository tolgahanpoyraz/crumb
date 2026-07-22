import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Centered icon + title + body used by the "Verify your email" and
/// "Check your email" confirmation screens.
class ConfirmationBody extends StatelessWidget {
  const ConfirmationBody({
    super.key,
    required this.title,
    required this.leadStrong,
    required this.email,
    required this.trail,
  });

  final String title;
  final String leadStrong;
  final String email;
  final String trail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            color: Color(0xFFE7F6EE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF2F9D63),
            size: 34,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 9),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: leadStrong),
              TextSpan(
                text: email,
                style: GoogleFonts.hankenGrotesk(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: trail),
            ],
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
