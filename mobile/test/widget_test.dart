import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  setUpAll(() {
    // Tests run offline; use the bundled fallback instead of fetching fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('Crumb theme exposes the brand palette', () {
    final theme = AppTheme.light;

    expect(theme.colorScheme.primary, AppColors.coral);
    expect(theme.colorScheme.secondary, AppColors.coralLight);
    expect(theme.scaffoldBackgroundColor, AppColors.appBg);
  });

  testWidgets('Crumb form controls render with the shared theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              const TextField(
                decoration: InputDecoration(labelText: 'School email'),
              ),
              FilledButton(
                onPressed: () {},
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('School email'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    final buttonContext = tester.element(find.byType(FilledButton));
    final buttonTheme = Theme.of(buttonContext).filledButtonTheme;
    final background = buttonTheme.style?.backgroundColor?.resolve({});
    expect(background, AppColors.coral);
  });
}
