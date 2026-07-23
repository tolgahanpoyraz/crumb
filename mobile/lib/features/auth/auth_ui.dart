import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../api/api_config.dart';
import '../../theme/app_theme.dart';

const _emptyBar = Color(0xFFF0E0D6);

String initialsFor(String displayName) {
  final words = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) {
    return '?';
  }

  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

/// Avatar with the subtle #f2e5db ring frame. Shows the uploaded image when
/// [avatarKey] is present, otherwise an initials fallback.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.displayName,
    required this.avatarKey,
    this.avatarVersion,
    this.size = 66,
  });

  final String displayName;
  final String? avatarKey;

  /// Bumped whenever the avatar is re-uploaded, so the URL changes and the
  /// cached image for the (unchanged) S3 key is not shown stale.
  final int? avatarVersion;
  final double size;

  @override
  Widget build(BuildContext context) {
    final inner = size - 5;
    final hasImage = avatarKey != null && avatarKey!.isNotEmpty;
    final imageUrl = hasImage
        ? '${ApiConfig.imageBaseUrl}/$avatarKey${avatarVersion == null ? '' : '?v=$avatarVersion'}'
        : null;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.border,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.appBg,
          shape: BoxShape.circle,
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: hasImage
            ? null
            : Text(
                initialsFor(displayName),
                style: GoogleFonts.fredoka(
                  color: AppColors.textPrimary,
                  fontSize: inner * 0.36,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Brand gradient shown behind the [AuthScaffold] header.
enum AuthHeaderVariant { coral, green }

/// Scrollable auth screen: coral (or green) brand header (Eugene sticker +
/// wordmark + tagline) over a form body. Used for every signed-out auth screen.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.sticker,
    required this.tagline,
    required this.children,
    this.showBack = false,
    this.variant = AuthHeaderVariant.coral,
  });

  final String sticker;
  final String tagline;
  final List<Widget> children;
  final bool showBack;
  final AuthHeaderVariant variant;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                _BrandHeader(
                  sticker: sticker,
                  tagline: tagline,
                  showBack: showBack,
                  variant: variant,
                ),
                // Rounded panel edge overlapping the gradient, per the handoff.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.panelBg,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                26,
                AppTheme.pagePadding,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.sticker,
    required this.tagline,
    required this.showBack,
    required this.variant,
  });

  final String sticker;
  final String tagline;
  final bool showBack;
  final AuthHeaderVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: variant == AuthHeaderVariant.green
              ? const [AppColors.greenLight, AppColors.green]
              : const [AppColors.coralLight, AppColors.coral],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 14, 30, 46),
          child: Column(
            children: [
              if (showBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ),
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/eugene/$sticker', fit: BoxFit.contain),
              ),
              const SizedBox(height: 14),
              Text(
                'crumb',
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tagline,
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small settings-style scaffold with a back nav row (Edit profile, etc.).
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTheme.pagePadding,
        leadingWidth: AppTheme.pagePadding + 52,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppTheme.pagePadding),
          child: _BackButton(),
        ),
        title: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            8,
            AppTheme.pagePadding,
            32,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.inputBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).maybePop(),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF7A5A4D),
          ),
        ),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: GoogleFonts.hankenGrotesk(
          color: AppColors.fieldLabel,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (trailing == null) {
      return text;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [text, trailing!],
    );
  }
}

/// Password field with a show/hide eye toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.hintText,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}

enum PasswordStrength {
  empty(0, '', _emptyBar),
  weak(1, 'Too short — use 8+ characters.', AppColors.warnIcon),
  fair(2, 'Use 8+ characters with a number.', Color(0xFFE8943A)),
  good(3, 'Almost there — add a number.', Color(0xFF8BC23F)),
  strong(4, 'Strong — 8+ characters with a number.', Color(0xFF4FB783));

  const PasswordStrength(this.bars, this.hint, this.color);

  final int bars;
  final String hint;
  final Color color;

  static PasswordStrength of(String password) {
    if (password.isEmpty) {
      return PasswordStrength.empty;
    }

    final hasNumber = password.contains(RegExp(r'\d'));
    final hasVariety = password.contains(RegExp(r'[A-Z]')) ||
        password.contains(RegExp(r'[^A-Za-z0-9]'));

    if (password.length < 6) {
      return PasswordStrength.weak;
    }
    if (password.length < 8 || !hasNumber) {
      return PasswordStrength.fair;
    }
    return hasVariety ? PasswordStrength.strong : PasswordStrength.good;
  }
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrength.of(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final filled = index < strength.bars;
            return Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index < 3 ? 5 : 0),
                decoration: BoxDecoration(
                  color: filled ? strength.color : _emptyBar,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        if (strength.hint.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            strength.hint,
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthMessageBanner extends StatelessWidget {
  const AuthMessageBanner({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final fg = isError ? AppColors.error : const Color(0xFF2F9D63);
    final bg = isError ? const Color(0xFFFFE6E2) : const Color(0xFFE7F6EE);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: fg,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.hankenGrotesk(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthButtonSpinner extends StatelessWidget {
  const AuthButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}

/// Muted link row shown centered under the primary button, e.g.
/// "New to Crumb? Create an account".
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$prompt ',
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.coral,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
