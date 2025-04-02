import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recipe_app/utils/mecab_wrapper.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = FakePathProviderPlatform();

  setUpAll(() async {
    await MecabWrapper().initialize(); // Required for segmentation
  });

  group('segment', () {
    testWidgets('Mecab segments text', (tester) async {
      final result = MecabWrapper().segment('私はチーズが好きです');
      expect(result, contains('チーズ'));
    });
  });

  group('preprocessText', () {
    testWidgets('English input - passes input through', (tester) async {
      final input = 'running walks talked';
      final output = MecabWrapper().tokenizeJapaneseText(input);
      expect(output, 'running walks talked');
    });

    testWidgets('Japanese input - segmentation using Mecab', (tester) async {
      final input = '私は学生です';
      final output = MecabWrapper().tokenizeJapaneseText(input);
      expect(output.split(' ').length, greaterThan(1));
      expect(output.contains('私'), isTrue);
    });

    testWidgets('Mixed input - Japanese takes precedence', (tester) async {
      final input = '今日はrunningをした';
      final output = MecabWrapper().tokenizeJapaneseText(input);
      expect(output.contains('running'), isTrue);
      expect(output.contains('今日'), isTrue);
    });

    testWidgets('Empty input returns empty string', (tester) async {
      final input = '';
      final output = MecabWrapper().tokenizeJapaneseText(input);
      expect(output, '');
    });
  });
}
