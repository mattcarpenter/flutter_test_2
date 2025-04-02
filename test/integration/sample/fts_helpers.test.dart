// integration_test/fts_helpers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recipe_app/database/fts_helpers.dart';
import 'package:recipe_app/utils/mecab_wrapper.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = FakePathProviderPlatform();

  setUpAll(() async {
    await MecabWrapper().initialize(); // Required for segmentation
  });

  group('preprocessText', () {
    testWidgets('English input - basic stemming', (tester) async {
      final input = 'running walks talked';
      final output = preprocessText(input);
      expect(output, 'run walk talk');
    });

    testWidgets('English input - handles extra whitespace', (tester) async {
      final input = '  walking    running \n talking ';
      final output = preprocessText(input);
      expect(output, 'walk run talk');
    });

    testWidgets('Japanese input - segmentation using Mecab', (tester) async {
      final input = '私は学生です';
      final output = preprocessText(input);
      expect(output.split(' ').length, greaterThan(1));
      expect(output.contains('私'), isTrue);
    });

    testWidgets('Mixed input - Japanese takes precedence', (tester) async {
      final input = '今日はrunningをした';
      final output = preprocessText(input);
      expect(output.contains('running'), isTrue);
      expect(output.contains('今日'), isTrue);
    });

    testWidgets('Empty input returns empty string', (tester) async {
      final input = '';
      final output = preprocessText(input);
      expect(output, '');
    });

    testWidgets('Whitespace-only input returns empty string', (tester) async {
      final input = '   \n\t  ';
      final output = preprocessText(input);
      expect(output, '');
    });
  });
}
