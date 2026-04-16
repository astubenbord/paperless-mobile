import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_localized_date_picker.dart';
import 'package:paperless_mobile/core/widgets/future_or_builder.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/single_label_form_field.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/sharing/view/widgets/file_thumbnail.dart';
import 'package:paperless_mobile/features/tasks/model/pending_tasks_notifier.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';

class DocumentUploadResult {
  final bool success;
  final String? taskId;

  DocumentUploadResult(this.success, this.taskId);
}

class DocumentUploadPreparationPage extends StatefulWidget {
  final FutureOr<Uint8List> fileBytes;
  final String? title;
  final String? filename;
  final String? fileExtension;
  final bool instantUpload;

  const DocumentUploadPreparationPage({
    super.key,
    required this.fileBytes,
    this.title,
    this.filename,
    this.fileExtension,
    this.instantUpload = false,
  });

  @override
  State<DocumentUploadPreparationPage> createState() =>
      _DocumentUploadPreparationPageState();
}

class _DocumentUploadPreparationPageState
    extends State<DocumentUploadPreparationPage> {
  static const fkFileName = "filename";
  static final fileNameDateFormat = DateFormat("yyyy_MM_ddTHH_mm_ss");

  final GlobalKey<FormBuilderState> _formKey = GlobalKey();
  final _now = DateTime.now();

  Map<String, String> _errors = {};
  double? _uploadProgress;
  late bool _syncTitleAndFilename;

  @override
  void initState() {
    super.initState();
    _syncTitleAndFilename = widget.filename == null && widget.title == null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.instantUpload) {
        _onSubmit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      resizeToAvoidBottomInset: true,
      floatingActionButton: Visibility(
        visible: MediaQuery.of(context).viewInsets.bottom == 0,
        child: FloatingActionButton.extended(
          heroTag: "fab_document_upload",
          onPressed: _uploadProgress == null ? _onSubmit : null,
          label: _uploadProgress == null
              ? Text(S.of(context)!.upload)
              : Text(S.of(context)!.documentUploadUploading),
          icon: _uploadProgress == null
              ? const Icon(Icons.upload)
              : SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    value: _uploadProgress,
                  ),
                ).padded(4),
        ),
      ),
      body: FormBuilder(
        key: _formKey,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                leading: const BackButton(),
                pinned: true,
                expandedHeight: 150,
                flexibleSpace: FlexibleSpaceBar(
                  background: FutureOrBuilder<Uint8List>(
                    future: widget.fileBytes,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      return Stack(
                        alignment: AlignmentGeometry.topCenter,
                        children: [
                          FileThumbnail(
                            bytes: snapshot.data!,
                            fit: BoxFit.fitWidth,
                            width: MediaQuery.sizeOf(context).width,
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  title: Text(S.of(context)!.prepareDocument),
                  collapseMode: CollapseMode.pin,
                ),
              ),
            ),
          ],
          body: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Builder(
              builder: (context) {
                return CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    SliverList.list(
                      children: [
                        // Title
                        FormBuilderTextField(
                          autovalidateMode: AutovalidateMode.always,
                          name: 'title',
                          initialValue:
                              widget.title ??
                              "scan_${fileNameDateFormat.format(_now)}",
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return S.of(context)!.thisFieldIsRequired;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: S.of(context)!.title,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _formKey.currentState?.fields['title']
                                    ?.didChange("");
                                if (_syncTitleAndFilename) {
                                  _formKey.currentState?.fields[fkFileName]
                                      ?.didChange("");
                                }
                              },
                            ),
                            errorText: _errors['title'],
                          ),
                          onChanged: (value) {
                            final String transformedValue = _formatFilename(
                              value ?? '',
                            );
                            if (_syncTitleAndFilename) {
                              _formKey.currentState?.fields[fkFileName]
                                  ?.didChange(transformedValue);
                            }
                          },
                        ),
                        // Filename
                        FormBuilderTextField(
                          autovalidateMode: AutovalidateMode.always,
                          readOnly: _syncTitleAndFilename,
                          enabled: !_syncTitleAndFilename,
                          name: fkFileName,
                          decoration: InputDecoration(
                            labelText: S.of(context)!.fileName,
                            suffixText: widget.fileExtension,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _formKey
                                  .currentState
                                  ?.fields[fkFileName]
                                  ?.didChange(''),
                            ),
                          ),
                          initialValue:
                              widget.filename ??
                              "scan_${fileNameDateFormat.format(_now)}",
                        ),
                        // Synchronize title and filename
                        SwitchListTile(
                          value: _syncTitleAndFilename,
                          onChanged: (value) {
                            setState(() => _syncTitleAndFilename = value);
                            if (_syncTitleAndFilename) {
                              final String transformedValue = _formatFilename(
                                _formKey.currentState?.fields['title']?.value
                                    as String,
                              );
                              if (_syncTitleAndFilename) {
                                _formKey.currentState?.fields[fkFileName]
                                    ?.didChange(transformedValue);
                              }
                            }
                          },
                          title: Text(
                            S.of(context)!.synchronizeTitleAndFilename,
                          ),
                        ),
                        // Created at
                        FormBuilderLocalizedDatePicker(
                          name: 'created',
                          firstDate: DateTime(1000, 1, 1),
                          lastDate: DateTime(9999, 12, 31),
                          labelText: "${S.of(context)!.createdAt} *",
                          allowUnset: true,
                        ),
                        // Correspondent
                        if (context.uiSettings$.canViewCorrespondents)
                          SingleLabelFormField<Correspondent>(
                            query: context.correspondentRepository
                                .getAllQuery(),
                            onAddLabel:
                                context.uiSettings$.canCreateCorrespondents
                                ? (initialName) => CreateLabelRoute(
                                    LabelType.correspondent,
                                    name: initialName,
                                  ).push<Correspondent>(context)
                                : null,
                            addLabelText:
                                context.uiSettings$.canCreateCorrespondents
                                ? S.of(context)!.addCorrespondent
                                : null,
                            labelText: "${S.of(context)!.correspondent} *",
                            name: 'correspondent',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        // Document type
                        if (context.uiSettings$.canViewDocumentTypes)
                          SingleLabelFormField<DocumentType>(
                            onAddLabel:
                                context.uiSettings$.canCreateDocumentTypes
                                ? (initialName) => CreateLabelRoute(
                                    LabelType.documentType,
                                    name: initialName,
                                  ).push<DocumentType>(context)
                                : null,
                            addLabelText:
                                context.uiSettings$.canCreateDocumentTypes
                                ? S.of(context)!.addDocumentType
                                : null,
                            labelText: "${S.of(context)!.documentType} *",
                            name: 'document_type',
                            query: context.documentTypeRepository.getAllQuery(),
                            prefixIcon: const Icon(Icons.description_outlined),
                          ),
                        if (context.uiSettings$.canViewTags)
                          TagsFormField(
                            name: 'tags',
                            allowCreation: true,
                            allowExclude: false,
                          ),
                        Text(
                          "* ${S.of(context)!.uploadInferValuesHint}",
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.justify,
                        ).padded(),
                        const SizedBox(height: 300),
                      ].padded(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }
    try {
      final formValues = _formKey.currentState!.value;

      final correspondent = formValues['correspondent'] as int?;
      final docType = formValues['document_type'] as int?;
      final tags = formValues['tags'] as TagsQuery?;
      final createdAt = formValues['created'] as FormDateTime?;
      final title = formValues['title'] as String;

      final asn = formValues['asn'] as int?;
      final mutationState = await context.documentRepository
          .createDocumentMutation(
            await widget.fileBytes,
            filename: _padWithExtension(
              _formKey.currentState?.value[fkFileName],
              widget.fileExtension,
            ),
            title: title,
            documentType: docType,
            correspondent: correspondent,
            tags: tags?.mapOrNull(ids: (value) => value.include) ?? [],
            createdAt: createdAt?.toDateTime(),
            archiveSerialNumber: asn,
          )
          .mutate();

      final taskId = mutationState.data;
      if (mounted) {
        if (taskId != null) {
          context.read<PendingTasksNotifier>().listenToTaskChanges(taskId);
        }
        showSnackBar(
          context,
          S.of(context)!.documentSuccessfullyUploadedProcessing,
        );
        context.pop(DocumentUploadResult(true, mutationState.data));
      }
    } on PaperlessApiException catch (error) {
      if (mounted) {
        showInfoMessage(
          context,
          InfoMessageException(code: error.code, message: error.details),
        );
      }
    } on PaperlessFormValidationException catch (exception) {
      setState(() => _errors = exception.validationMessages);
    } catch (error, stackTrace) {
      logger.fe(
        "An unknown error occurred during document upload.",
        className: runtimeType.toString(),
        methodName: "_onSubmit",
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        showErrorMessage(
          context,
          const PaperlessApiException.unknown(),
          stackTrace,
        );
      }
    }
  }

  String _padWithExtension(String source, [String? extension]) {
    final ext = extension ?? '.pdf';
    return source.endsWith(ext) ? source : '$source$ext';
  }

  String _formatFilename(String source) {
    return source.replaceAll(RegExp(r"[\W_]"), "_").toLowerCase();
  }

  // Future<Color> _computeAverageColor() async {
  //   final bitmap = img.decodeImage(await widget.fileBytes);
  //   if (bitmap == null) {
  //     return Colors.black;
  //   }
  //   int redBucket = 0;
  //   int greenBucket = 0;
  //   int blueBucket = 0;
  //   int pixelCount = 0;

  //   for (int y = 0; y < bitmap.height; y++) {
  //     for (int x = 0; x < bitmap.width; x++) {
  //       final c = bitmap.getPixel(x, y);

  //       pixelCount++;
  //       redBucket += c.r.toInt();
  //       greenBucket += c.g.toInt();
  //       blueBucket += c.b.toInt();
  //     }
  //   }

  //   return Color.fromRGBO(
  //     redBucket ~/ pixelCount,
  //     greenBucket ~/ pixelCount,
  //     blueBucket ~/ pixelCount,
  //     1,
  //   );
  // }
}
