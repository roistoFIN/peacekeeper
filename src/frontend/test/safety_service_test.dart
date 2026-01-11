import 'package:flutter_test/flutter_test.dart';
import 'package:peacekeeper/services/safety_service.dart';
import 'package:peacekeeper/services/debug_service.dart';

void main() {
  setUp(() {
    DebugService.isEnabled = false;
  });

  group('SafetyService.validateBlamePatterns', () {
    final service = SafetyService();
    final patterns = [
      r'(?i)\byou\s+(always|never)',
      r'(?i)\byou\s+made\s+me',
    ];

    test('returns true for matching blame pattern (always)', () {
      expect(service.validateBlamePatterns('You always do this', patterns), isTrue);
    });

    test('returns true for matching blame pattern (never)', () {
      expect(service.validateBlamePatterns('You never listen', patterns), isTrue);
    });

    test('returns true for matching blame pattern (case insensitive)', () {
      expect(service.validateBlamePatterns('you ALWAYS forget', patterns), isTrue);
    });

    test('returns true for "you made me"', () {
      expect(service.validateBlamePatterns('You made me angry', patterns), isTrue);
    });

    test('returns false for non-blaming observation', () {
      expect(service.validateBlamePatterns('I saw the dishes', patterns), isFalse);
    });

    test('returns false for null patterns', () {
      expect(service.validateBlamePatterns('You always', null), isFalse);
    });

    test('returns false for empty patterns', () {
      expect(service.validateBlamePatterns('You always', []), isFalse);
    });
    
    test('handles invalid regex gracefully', () {
      final badPatterns = ['[']; // Invalid regex
      expect(service.validateBlamePatterns('test', badPatterns), isFalse);
    });
  });
}
