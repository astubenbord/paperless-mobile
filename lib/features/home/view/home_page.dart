import 'dart:developer';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_cubit.dart';
import 'package:paperless_mobile/core/bloc/paperless_statistics_cubit.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/core/widgets/offline_banner.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/saved_view_cubit.dart';
import 'package:paperless_mobile/features/documents/repository/document_repository.dart';
import 'package:paperless_mobile/features/documents/view/pages/documents_page.dart';
import 'package:paperless_mobile/features/home/view/widget/bottom_navigation_bar.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/inbox/view/inbox_page.dart';
import 'package:paperless_mobile/features/labels/bloc/label_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/labels/storage_path/bloc/storage_path_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/labels/view/pages/labels_page.dart';
import 'package:paperless_mobile/features/scan/bloc/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/scan/view/scanner_page.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/util.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData(context).then(
      (_) async {
        FlutterNativeSplash.remove();
        if (BlocProvider.of<ApplicationSettingsCubit>(context)
            .state
            .showInboxOnStartup) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: getIt<PaperlessStatisticsCubit>(),
                child: LabelBlocProvider(
                  child: BlocProvider.value(
                    value: DocumentsCubit(getIt<DocumentRepository>()),
                    child: const InboxPage(),
                  ),
                ),
              ),
            ),
          );
          getIt<DocumentsCubit>().reloadDocuments();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      //Only re-initialize data if the connectivity changed from not connected to connected
      listenWhen: (previous, current) => current == ConnectivityState.connected,
      listener: (context, state) {
        _initializeData(context);
      },
      builder: (context, connectivityState) {
        return Scaffold(
          appBar: connectivityState == ConnectivityState.connected
              ? null
              : const OfflineBanner(),
          key: rootScaffoldKey,
          bottomNavigationBar: BottomNavBar(
            selectedIndex: _currentIndex,
            onNavigationChanged: (index) =>
                setState(() => _currentIndex = index),
          ),
          drawer: const InfoDrawer(),
          body: [
            BlocProvider.value(
              value: getIt<DocumentsCubit>(),
              child: const DocumentsPage(),
            ),
            BlocProvider.value(
              value: getIt<DocumentScannerCubit>(),
              child: const ScannerPage(),
            ),
            const LabelsPage(),
          ][_currentIndex],
        );
      },
    );
  }

  Future<void> _initializeData(BuildContext context) {
    try {
      return Future.wait([
        BlocProvider.of<PaperlessServerInformationCubit>(context)
            .updateInformtion(),
        BlocProvider.of<PaperlessStatisticsCubit>(context).updateStatistics(),
        BlocProvider.of<DocumentTypeCubit>(context).initialize(),
        BlocProvider.of<CorrespondentCubit>(context).initialize(),
        BlocProvider.of<TagCubit>(context).initialize(),
        BlocProvider.of<StoragePathCubit>(context).initialize(),
        BlocProvider.of<SavedViewCubit>(context).initialize(),
      ]);
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
      return Future.error(error);
    }
  }
}
