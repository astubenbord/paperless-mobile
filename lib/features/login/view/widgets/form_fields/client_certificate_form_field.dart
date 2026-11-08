import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:path/path.dart' as p;
import 'obscured_input_text_form_field.dart';

class ClientCertificateFormField extends StatefulWidget {
  static const fkClientCertificate = 'clientCertificate';

  final String? initialPassphrase;
  final String? initialFilename;
  final Uint8List? initialBytes;

  final ValueChanged<ClientCertificate?>? onChanged;
  const ClientCertificateFormField({
    super.key,
    this.onChanged,
    this.initialPassphrase,
    this.initialBytes,
    this.initialFilename,
  });

  @override
  State<ClientCertificateFormField> createState() =>
      _ClientCertificateFormFieldState();
}

class _ClientCertificateFormFieldState extends State<ClientCertificateFormField>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FormBuilderField<ClientCertificate?>(
      key: const ValueKey('login-client-cert'),
      name: ClientCertificateFormField.fkClientCertificate,
      onChanged: widget.onChanged,
      initialValue: widget.initialBytes != null
          ? ClientCertificate(
              bytes: widget.initialBytes!,
              filename: widget.initialFilename!,
              passphrase: widget.initialPassphrase,
            )
          : null,
      builder: (field) {
        final theme = Theme.of(
          context,
        ).copyWith(dividerColor: Colors.transparent);
        return Theme(
          data: theme,
          child: ExpansionTile(
            title: Text(S.of(context)!.clientcertificate),
            subtitle: Text(S.of(context)!.configureMutualTLSAuthentication),
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  errorText: field.errorText,
                  border: InputBorder.none,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _onSelectFile(field),
                              child: Text(S.of(context)!.select),
                            ),
                            _buildSelectedFileText(field).paddedOnly(left: 8),
                          ],
                        ),
                        if (field.value?.filename != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              field.didChange(null);
                            }),
                          ),
                      ],
                    ).padded(8),
                    // ListTile(
                    //   leading: ElevatedButton(
                    //     onPressed: () => _onSelectFile(field),
                    //     child: Text(S.of(context)!.select),
                    //   ),
                    //   title: _buildSelectedFileText(field),
                    //   trailing: AbsorbPointer(
                    //     absorbing: field.value == null,
                    //     child: _selectedFile != null
                    //         ? IconButton(
                    //             icon: const Icon(Icons.close),
                    //             onPressed: () => setState(() {
                    //               _selectedFile = null;
                    //               field.didChange(null);
                    //             }),
                    //           )
                    //         : null,
                    //   ),
                    // ),
                    if (field.value?.filename != null) ...[
                      ObscuredInputTextFormField(
                        key: const ValueKey('login-client-cert-passphrase'),
                        initialValue: field.value?.passphrase,
                        onChanged: (value) => field.didChange(
                          field.value?.copyWith(passphrase: value),
                        ),
                        label: S.of(context)!.passphrase,
                      ).padded(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onSelectFile(FormFieldState<ClientCertificate?> field) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.single.path == null) {
      return;
    }
    final path = result.files.single.path!;
    if (p.extension(path) != '.pfx') {
      if (mounted) {
        showSnackBar(context, S.of(context)!.invalidCertificateFormat);
      }
      return;
    }
    File file = File(path);
    final bytes = await file.readAsBytes();

    final changedValue = ClientCertificate(
      bytes: bytes,
      filename: p.basename(path),
    );
    field.didChange(changedValue);
  }

  Widget _buildSelectedFileText(FormFieldState<ClientCertificate?> field) {
    if (field.value == null) {
      return Text(
        S.of(context)!.selectFile,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.apply(color: Theme.of(context).hintColor),
      );
    } else {
      return Text(
        p.basename(field.value!.filename),
        style: const TextStyle(overflow: TextOverflow.ellipsis),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}
