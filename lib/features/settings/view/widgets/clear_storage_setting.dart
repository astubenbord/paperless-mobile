import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cm;
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:provider/provider.dart';

class ClearStorageSetting extends StatelessWidget {
  const ClearStorageSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("Clear data"),
      subtitle:
          Text("Remove downloaded files, scans and clear the cache's content"),
      onTap: () {
        Provider.of<cm.CacheManager>(context).emptyCache();
        FileService.clearUserData();
      },
    );
  }
}
