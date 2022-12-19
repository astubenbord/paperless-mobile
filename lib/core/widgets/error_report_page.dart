import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/model/github_error_report.model.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';

class ErrorReportPage extends StatefulWidget {
  final StackTrace? stackTrace;
  const ErrorReportPage({super.key, this.stackTrace});

  @override
  State<ErrorReportPage> createState() => _ErrorReportPageState();
}

class _ErrorReportPageState extends State<ErrorReportPage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey();

  static const String shortDescriptionKey = 'shortDescription';
  static const String longDescriptionKey = 'longDescription';

  bool _stackTraceCopied = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Report error'),
        actions: [
          TextButton(
            onPressed: _onSubmit,
            child: const Text('Submit'),
          ),
        ],
      ),
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              '''Oops, an error has occurred!
In order to improve the app and prevent messages like these, it is greatly appreciated if you report this error with a description of what happened and the actions leading up to this window. 
Please fill the fields below and create a new issue in GitHub. Thanks!
Note: If you have the GitHub Android app installed, the descriptions will not be taken into account! Skip these here and fill them in the GitHub issues form after submitting this report.''',
              style: Theme.of(context).textTheme.bodyMedium,
            ).padded(),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ).padded(),
            FormBuilderTextField(
              name: shortDescriptionKey,
              decoration: const InputDecoration(
                  label: Text('Short Description'),
                  hintText:
                      'Please provide a brief description of what went wrong.'),
            ).padded(),
            FormBuilderTextField(
              name: shortDescriptionKey,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                label: Text('Detailled Description'),
                hintText:
                    'Please describe the exact actions taken that caused this error. Provide as much details as possible.',
              ),
            ).padded(),
            if (widget.stackTrace != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stack Trace',
                    style: Theme.of(context).textTheme.titleMedium,
                  ).paddedOnly(top: 8.0, left: 8.0, right: 8.0),
                  TextButton.icon(
                    label: const Text('Copy'),
                    icon: const Icon(Icons.copy),
                    onPressed: _copyStackTrace,
                  ),
                ],
              ),
              Text(
                'Since stack traces cannot be attached to the GitHub issue url, please copy the content of the stackTrace and paste it in the issue description. This will greatly increase the chance of quickly resolving the issue!',
                style: Theme.of(context).textTheme.bodySmall,
              ).padded(),
              Text(
                widget.stackTrace.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ).padded(),
            ]
          ],
        ),
      ),
    );
  }

  void _copyStackTrace() {
    Clipboard.setData(
      ClipboardData(text: '```${widget.stackTrace.toString()}```'),
    ).then(
      (_) {
        setState(() => _stackTraceCopied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Stack trace copied to clipboard.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void _onSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final fk = _formKey.currentState!.value;
      if (!_stackTraceCopied) {
        final continueSubmission = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Continue without stack trace?'),
                content: const Text(
                  'It seems you have not yet copied the stack trace. The stack trace provides valuable insights into where an error came from and how it could be fixed. Are you sure you want to continue without providing the stack trace?',
                ),
                actionsAlignment: MainAxisAlignment.end,
                actions: [
                  TextButton(
                    child: const Text('Yes, continue'),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  TextButton(
                    child: const Text('No, copy stack trace'),
                    onPressed: () {
                      _copyStackTrace();
                      Navigator.pop(context, true);
                    },
                  ),
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ) ??
            false;
        if (!continueSubmission) {
          return;
        }
      }
      Navigator.pop(
        context,
        GithubErrorReport(
          shortDescription: fk[shortDescriptionKey],
          longDescription: fk[longDescriptionKey],
        ),
      );
    }
  }
}
