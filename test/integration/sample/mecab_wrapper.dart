import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recipe_app/utils/mecab_wrapper.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = FakePathProviderPlatform();

  testWidgets('Mecab segments text', (tester) async {
    await MecabWrapper().initialize(); // uses path_provider under the hood

    final result = MecabWrapper().segment('私はチーズが好きです');
    expect(result, contains('チーズ'));
  });
}
