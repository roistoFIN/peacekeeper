import 'package:flutter_test/flutter_test.dart';
import 'package:peacekeeper/services/safety_service.dart';
import 'package:peacekeeper/services/debug_service.dart';

void main() {
  setUp(() {
    DebugService.isEnabled = false;
  });

  group('SafetyService.validateLocalRules', () {
    final service = SafetyService();
    
    final rules = {
      'blame_patterns': [
        r'(?i)\byou\s+(always|never)',
        r'(?i)\byou\s+made\s+me',
      ],
      'violent_words': [
        'stupid', 'cunt', 'hate'
      ]
    };

    test('returns true for matching blame pattern (always)', () {
      expect(service.validateLocalRules('You always do this', rules), isTrue);
    });

    test('returns true for matching blame pattern (never)', () {
      expect(service.validateLocalRules('You never listen', rules), isTrue);
    });

    test('returns true for matching blame pattern (case insensitive)', () {
      expect(service.validateLocalRules('you ALWAYS forget', rules), isTrue);
    });

    test('returns true for "you made me"', () {
      expect(service.validateLocalRules('You made me angry', rules), isTrue);
    });

    test('returns true for violent words', () {
      expect(service.validateLocalRules('You are a cunt', rules), isTrue);
      expect(service.validateLocalRules('don\'t be stupid', rules), isTrue);
    });

    test('returns false for non-blaming observation', () {
      expect(service.validateLocalRules('I saw the dishes', rules), isFalse);
    });

    test('returns false for null rules', () {
      expect(service.validateLocalRules('You always', null), isFalse);
    });

    test('returns false for empty rules', () {
      expect(service.validateLocalRules('You always', {}), isFalse);
    });
  });
}