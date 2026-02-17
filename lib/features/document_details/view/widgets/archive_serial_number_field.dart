import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/loading_status.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_details/cubit/document_details_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';

class ArchiveSerialNumberField extends StatefulWidget {
  final DocumentModel document;
  const ArchiveSerialNumberField({
    super.key,
    required this.document,
  });

  @override
  State<ArchiveSerialNumberField> createState() =>
      _ArchiveSerialNumberFieldState();
}

class _ArchiveSerialNumberFieldState extends State<ArchiveSerialNumberField> {
  late final TextEditingController _asnEditingController;
  late bool _showClearButton;
  bool _canUpdate = false;
  Map<String, dynamic> _errors = {};

  @override
  void initState() {
    super.initState();
    _asnEditingController = TextEditingController(
      text: widget.document.archiveSerialNumber?.toString(),
    )..addListener(_clearButtonListener);
    _showClearButton = widget.document.archiveSerialNumber != null;
  }

  void _clearButtonListener() {
    setState(() {
      _showClearButton = _asnEditingController.text.isNotEmpty;
      _canUpdate = int.tryParse(_asnEditingController.text) !=
          widget.document.archiveSerialNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userCanEditDocument =
        context.watch<LocalUserAccount>().paperlessUser.canEditDocuments;
    return BlocListener<DocumentDetailsCubit, DocumentDetailsState>(
      listenWhen: (previous, current) =>
          previous.status == LoadingStatus.loaded &&
          current.status == LoadingStatus.loaded &&
          previous.document!.archiveSerialNumber !=
              current.document!.archiveSerialNumber,
      listener: (context, state) {
        _asnEditingController.text =
            state.document!.archiveSerialNumber?.toString() ?? '';
        setState(() {
          _canUpdate = false;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            enabled: userCanEditDocument,
            controller: _asnEditingController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() => _errors = {});
            },
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onFieldSubmitted: (_) => _onSubmitted(),
            decoration: InputDecoration(
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showClearButton)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: userCanEditDocument
                          ? _asnEditingController.clear
                          : null,
                    ),
                  IconButton(
                    icon: const Icon(Icons.plus_one_rounded),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed:
                        context.watchInternetConnection && !_showClearButton
                            ? _onAutoAssign
                            : null,
                  ).paddedOnly(right: 8),
                ],
              ),
              errorText: _errors['archive_serial_number'],
              errorMaxLines: 2,
              labelText: S.of(context)!.archiveSerialNumber,
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.done),
            onPressed: context.watchInternetConnection && _canUpdate
                ? _onSubmitted
                : null,
            label: Text(S.of(context)!.save),
          ).padded(),
        ],
      ),
    );
  }

  Future<void> _onSubmitted() async {
    final value = _asnEditingController.text;
    final asn = int.tryParse(value);

    await context
        .read<DocumentDetailsCubit>()
        .assignAsn(widget.document, asn: asn)
        .then((value) => _onAsnUpdated())
        .onError<PaperlessApiException>(
      (error, stackTrace) {
        if (mounted) showErrorMessage(context, error, stackTrace);
      },
    ).onError<PaperlessFormValidationException>(
      (error, stackTrace) {
        setState(() => _errors = error.validationMessages);
      },
    );
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _onAutoAssign() async {
    await context
        .read<DocumentDetailsCubit>()
        .assignAsn(
          widget.document,
          autoAssign: true,
        )
        .then((value) => _onAsnUpdated())
        .onError<PaperlessApiException>(
      (error, stackTrace) {
        if (mounted) showErrorMessage(context, error, stackTrace);
      },
    ).catchError((error) {
      if (mounted) showGenericError(context, error);
    });
  }

  void _onAsnUpdated() {
    setState(() => _errors = {});
    FocusScope.of(context).unfocus();
    showSnackBar(context, S.of(context)!.archiveSerialNumberUpdated);
  }
}
