import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:provider/provider.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  late Future<PagedSearchResult<DocumentModel>> _trashedDocsFuture;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadTrashed();
  }

  void _loadTrashed() {
    _trashedDocsFuture = context.read<PaperlessTrashApi>().findTrashed(
          page: _currentPage,
        );
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 1;
      _loadTrashed();
    });
  }

  Future<void> _restoreDocument(int id) async {
    try {
      await context.read<PaperlessTrashApi>().restoreDocument(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document restored')),
      );
      _refresh();
    } on PaperlessApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore: ${e.details ?? e.code}')),
      );
    }
  }

  Future<void> _emptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash'),
        content: const Text(
          'This will permanently delete all trashed documents. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<PaperlessTrashApi>().emptyTrash();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trash emptied')),
      );
      _refresh();
    } on PaperlessApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to empty trash: ${e.details ?? e.code}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Empty Trash',
            onPressed: _emptyTrash,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<PagedSearchResult<DocumentModel>>(
          future: _trashedDocsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text('Failed to load trash: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final result = snapshot.data!;
            if (result.results.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              itemCount: result.results.length,
              itemBuilder: (context, index) {
                final doc = result.results[index];
                return _TrashDocumentTile(
                  document: doc,
                  onRestore: () => _restoreDocument(doc.id),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trash is empty',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrashDocumentTile extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onRestore;

  const _TrashDocumentTile({
    required this.document,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(document.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.restore, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onRestore();
        return false;
      },
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(
          document.title.isEmpty ? '(untitled)' : document.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Modified: ${_formatDate(document.modified)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.restore),
          tooltip: 'Restore',
          onPressed: onRestore,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
