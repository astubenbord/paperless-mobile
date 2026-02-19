import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class DocumentShareLinksWidget extends StatefulWidget {
  final DocumentModel document;

  const DocumentShareLinksWidget({super.key, required this.document});

  @override
  State<DocumentShareLinksWidget> createState() =>
      _DocumentShareLinksWidgetState();
}

class _DocumentShareLinksWidgetState extends State<DocumentShareLinksWidget> {
  List<ShareLink>? _shareLinks;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadShareLinks();
  }

  Future<void> _loadShareLinks() async {
    try {
      final api = context.read<PaperlessShareLinksApi>();
      final links =
          await api.getShareLinks(documentId: widget.document.id);
      if (mounted) {
        setState(() {
          _shareLinks = links;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverList.list(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.of(context)!.shareLinks,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_link, size: 18),
              label: Text(S.of(context)!.createShareLink),
              onPressed: () => _showCreateDialog(context),
            ),
          ],
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!_loading && (_shareLinks == null || _shareLinks!.isEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              S.of(context)!.noShareLinks,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        if (_shareLinks != null)
          ...(_shareLinks!.map((link) => _buildShareLinkTile(context, link))),
      ],
    );
  }

  Widget _buildShareLinkTile(BuildContext context, ShareLink link) {
    final serverUrl = context.read<LocalUserAccount>().serverUrl;
    final url = link.buildUrl(serverUrl);
    final expirationText = link.expiration != null
        ? DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(link.expiration!)
        : S.of(context)!.noExpiration;

    return Card(
      child: ListTile(
        leading: Icon(
          link.fileVersion == 'original'
              ? Icons.insert_drive_file_outlined
              : Icons.picture_as_pdf,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          url,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${link.fileVersion} - $expirationText',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: S.of(context)!.linkCopied,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                showSnackBar(context, S.of(context)!.linkCopied);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Theme.of(context).colorScheme.error),
              tooltip: S.of(context)!.revokeShareLink,
              onPressed: () => _revokeShareLink(link),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revokeShareLink(ShareLink link) async {
    try {
      final api = context.read<PaperlessShareLinksApi>();
      await api.deleteShareLink(link.id!);
      if (mounted) {
        setState(() {
          _shareLinks?.removeWhere((l) => l.id == link.id);
        });
      }
    } catch (e) {
      if (mounted) showGenericError(context, e);
    }
  }

  void _showCreateDialog(BuildContext context) {
    String fileVersion = 'archive';
    DateTime? expiration;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(S.of(context)!.createShareLink),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(context)!.fileVersion),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'archive',
                    label: Text(S.of(context)!.archive),
                  ),
                  ButtonSegment(
                    value: 'original',
                    label: Text(S.of(context)!.original),
                  ),
                ],
                selected: {fileVersion},
                onSelectionChanged: (selection) {
                  setDialogState(() => fileVersion = selection.first);
                },
              ),
              const SizedBox(height: 16),
              Text(S.of(context)!.expiration),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365 * 10)),
                  );
                  setDialogState(() => expiration = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon:
                        const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    expiration != null
                        ? DateFormat.yMMMd().format(expiration!)
                        : S.of(context)!.noExpiration,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _createShareLink(fileVersion, expiration);
              },
              child: Text(S.of(context)!.createShareLink),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createShareLink(
      String fileVersion, DateTime? expiration) async {
    try {
      final api = context.read<PaperlessShareLinksApi>();
      final link = await api.createShareLink(ShareLink(
        document: widget.document.id,
        fileVersion: fileVersion,
        expiration: expiration,
      ));
      if (mounted) {
        setState(() {
          _shareLinks ??= [];
          _shareLinks!.add(link);
        });
        final serverUrl = context.read<LocalUserAccount>().serverUrl;
        final url = link.buildUrl(serverUrl);
        Clipboard.setData(ClipboardData(text: url));
        showSnackBar(context, S.of(context)!.linkCopied);
      }
    } catch (e) {
      if (mounted) showGenericError(context, e);
    }
  }
}
