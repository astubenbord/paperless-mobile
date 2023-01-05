import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/view/widgets/password_text_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class ClientCertificateFormField extends StatefulWidget {
  static const fkClientCertificate = 'clientCertificate';

  final void Function(ClientCertificate? cert) onChanged;
  const ClientCertificateFormField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ClientCertificateFormField> createState() =>
      _ClientCertificateFormFieldState();
}

class _ClientCertificateFormFieldState
    extends State<ClientCertificateFormField> {
  RestorableString? _selectedFilePath;
  File? _selectedFile;
  @override
  Widget build(BuildContext context) {
    return FormBuilderField<ClientCertificate?>(
      key: const ValueKey('login-client-cert'),
      onChanged: widget.onChanged,
      initialValue: null,
      validator: (value) {
        if (value == null) {
          return null;
        }
        assert(_selectedFile != null);
        if (_selectedFile?.path.split(".").last != 'pfx') {
          return S
              .of(context)
              .loginPageClientCertificateSettingInvalidFileFormatValidationText;
        }
        return null;
      },
      builder: (field) {
        final theme =
            Theme.of(context).copyWith(dividerColor: Colors.transparent); //new
        return Theme(
          data: theme,
          child: ExpansionTile(
            title: Text(S.of(context).loginPageClientCertificateSettingLabel),
            subtitle: Text(
                S.of(context).loginPageClientCertificateSettingDescriptionText),
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  errorText: field.errorText,
                  border: InputBorder.none,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: ElevatedButton(
                        onPressed: () => _onSelectFile(field),
                        child: Text(S.of(context).genericActionSelectText),
                      ),
                      title: _buildSelectedFileText(field),
                      trailing: AbsorbPointer(
                        absorbing: field.value == null,
                        child: _selectedFile != null
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() {
                                  _selectedFile = null;
                                  field.didChange(null);
                                }),
                              )
                            : null,
                      ),
                    ),
                    if (_selectedFile != null) ...[
                      ObscuredInputTextFormField(
                        key: const ValueKey('login-client-cert-passphrase'),
                        initialValue: field.value?.passphrase,
                        onChanged: (value) => field.didChange(
                          field.value?.copyWith(passphrase: value),
                        ),
                        label: S
                            .of(context)
                            .loginPageClientCertificatePassphraseLabel,
                      ).padded(),
                    ] else
                      ...[]
                  ],
                ),
              ),
            ],
          ),
        );
      },
      name: ClientCertificateFormField.fkClientCertificate,
    );
  }

  Future<void> _onSelectFile(FormFieldState<ClientCertificate?> field) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _selectedFile = file;
      });
      final changedValue =
          field.value?.copyWith(bytes: file.readAsBytesSync()) ??
              ClientCertificate(bytes: file.readAsBytesSync());
      field.didChange(changedValue);
    }
  }

  Widget _buildSelectedFileText(FormFieldState<ClientCertificate?> field) {
    if (field.value == null) {
      assert(_selectedFile == null);
      return Text(
        S.of(context).loginPageClientCertificateSettingSelectFileText,
        style: TextStyle(color: Theme.of(context).hintColor),
      );
    } else {
      assert(_selectedFile != null);
      return Text(
        _selectedFile!.path.split("/").last,
        style: const TextStyle(
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }
}
