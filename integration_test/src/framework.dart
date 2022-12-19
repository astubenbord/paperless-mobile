import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/generated/l10n.dart';

Future<TestingFrameworkVariables> initializeTestingFramework(
    {String languageCode = 'en'}) async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configureDependencies('test');
  final translations = await S.load(
    Locale.fromSubtags(
      languageCode: languageCode,
    ),
  );
  return TestingFrameworkVariables(
    binding: binding,
    translations: translations,
  );
}

class TestingFrameworkVariables {
  final IntegrationTestWidgetsFlutterBinding binding;
  final S translations;

  TestingFrameworkVariables({
    required this.binding,
    required this.translations,
  });
}

Future<void> initAndLaunchTestApp(
  WidgetTester tester,
  Future<void> Function() initializationCallback,
) async {
  await initializationCallback();
  //runApp(const PaperlessMobileEntrypoint(authenticationCubit: ),));
}
