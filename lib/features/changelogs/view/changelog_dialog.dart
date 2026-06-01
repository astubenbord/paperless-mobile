import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_community/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      actionsPadding: const EdgeInsets.all(4),
      title: Text(S.of(context)!.changelog),
      content: FutureBuilder<String>(
        future: _loadChangelog(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator()).padded(24);
          }
          return SizedBox(width: 1000, child: Markdown(data: snapshot.data!));
        },
      ),
      actions: [
        TextButton(
          child: Text(S.of(context)!.close),
          onPressed: () {
            context.pop();
          },
        ),
      ],
    );
  }

  Future<String> _loadChangelog(BuildContext context) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final locale = switch (languageCode) {
      'de' => 'de-DE',
      _ => 'en-US',
    };
    String changelog = await rootBundle.loadString(
      'assets/changelogs/changelogs_$locale.md',
    );
    for (var versionNumber in _versionNumbers.keys) {
      changelog = changelog.replaceFirst(
        RegExp('# $versionNumber'),
        '# v${_versionNumbers[versionNumber]!}',
      );
    }
    return changelog;
  }
}

const _versionNumbers = {
  "7303": "5.0.0-alpha2",
  "7203": "5.0.0-alpha1",
  "7103": "4.5.0",
  "7003": "4.4.0",
  "6903": "4.3.5",
  "6803": "4.3.4",
  "6703": "4.3.3",
  "6603": "4.3.2",
  "6503": "4.3.1",
  "6203": "4.2.0-apikey-auth-rc1",
  "6103": "4.1.0",
  "6003": "4.0.6",
  "5903": "4.0.5",
  "5803": "4.0.4",
  "5703": "4.0.3",
  "5603": "4.0.2",
  "5503": "4.0.1",
  "5403": "4.0.0",
  "4053": "3.2.1",
  "4043": "3.2.0",
  "4033": "3.1.8",
  "4023": "3.1.7",
  "4013": "3.1.6",
  "4003": "3.1.5",
  "58": "3.1.4",
  "57": "3.1.3",
  "56": "3.1.2",
  "55": "3.1.1",
  "54": "3.1.0",
  "53": "3.0.6",
  "52": "3.0.5",
  "51": "3.0.4",
  "50": "3.0.3",
  "49": "3.0.2",
  "48": "3.0.1",
  "47": "3.0.0",
  "46": "2.3.11",
  "45": "2.3.10",
  "44": "2.3.9",
  "43": "2.3.8",
  "42": "2.3.7",
  "41": "2.3.6",
  "40": "2.3.5",
  "39": "2.3.4",
  "38": "2.3.3",
  "37": "2.3.2",
  "36": "2.3.1",
  "35": "2.3.0",
  "34": "2.2.6",
  "33": "2.2.5",
  "32": "2.2.4",
  "31": "2.2.3",
  "30": "2.2.2",
  "29": "2.2.1",
  "28": "2.2.0",
  "27": "2.1.0",
  "26": "2.0.9",
  "25": "2.0.8",
  "24": "2.0.7",
  "23": "2.0.6",
  "22": "2.0.5",
  "21": "2.0.4",
  "20": "2.0.3",
  "19": "2.0.2",
  "18": "2.0.1",
  "17": "2.0.0",
  "16": "1.5.3",
  "15": "1.5.2",
  "14": "1.5.1",
  "13": "1.5.0",
  "12": "1.4.1",
  "11": "1.4.0",
  "10": "1.3.1",
  "9": "1.3.0",
  "8": "1.2.2",
  "7": "1.2.1",
  "6": "1.2.0",
  "5": "1.1.0",
  "3": "1.0.5",
  "4": "1.0.6",
  "2": "1.0.4",
};
