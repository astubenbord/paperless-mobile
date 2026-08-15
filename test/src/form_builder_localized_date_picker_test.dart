import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/store/slices/local_user_account.dart';
import 'package:paperless_mobile/core/store/slices/user_profile.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_localized_date_picker.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'advances focus without validating an incomplete date',
    (tester) async {
      await tester.pumpWidget(
        Provider.value(
          value: LocalUserAccount(
            appUserId: 'test',
            serverUrl: 'https://example.com',
            apiVersion: 9,
            profile: UserProfile(
              profile: Profile(),
              uiSettings: UiSettingsView(
                user: UiSettingsViewUser(id: 1, username: 'test'),
              ),
            ),
          ),
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: FormBuilder(
                child: FormBuilderLocalizedDatePicker(
                  name: 'created',
                  labelText: 'Created at',
                  firstDate: DateTime(1000, 1, 1),
                  lastDate: DateTime(9999, 12, 31),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.enterText(find.byType(TextFormField).at(0), '12');
      await tester.pump();

      final secondInput = tester.widget<EditableText>(
        find.byType(EditableText).at(1),
      );
      expect(secondInput.focusNode.hasFocus, isTrue);
      expect(find.text('This field is required.'), findsNothing);
    },
  );
}