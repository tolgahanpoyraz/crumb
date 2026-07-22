import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/auth_ui.dart';

void main() {
  group('PasswordStrength', () {
    test('empty password has no bars', () {
      expect(PasswordStrength.of('').bars, 0);
    });

    test('short password is weak', () {
      expect(PasswordStrength.of('abc'), PasswordStrength.weak);
    });

    test('8+ chars with a number is at least good', () {
      expect(PasswordStrength.of('bread123').bars, greaterThanOrEqualTo(3));
    });

    test('length, number and variety is strong', () {
      expect(PasswordStrength.of('Bread123!'), PasswordStrength.strong);
    });
  });

  group('initialsFor', () {
    test('takes up to two initials, uppercased', () {
      expect(initialsFor('maya chen'), 'MC');
    });

    test('single name yields one initial', () {
      expect(initialsFor('Eugene'), 'E');
    });

    test('blank falls back to a placeholder', () {
      expect(initialsFor('   '), '?');
    });
  });
}
