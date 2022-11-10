import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/global_error_cubit.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/widgets/offline_banner.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/saved_view_cubit.dart';
import 'package:paperless_mobile/features/documents/view/pages/documents_page.dart';
import 'package:paperless_mobile/features/home/view/widget/bottom_navigation_bar.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/labels/storage_path/bloc/storage_path_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/labels/view/pages/labels_page.dart';
import 'package:paperless_mobile/features/scan/bloc/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/scan/view/scanner_page.dart';
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
    initializeLabelData(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GlobalErrorCubit, GlobalErrorState>(
      listener: (context, state) {
        if (state.hasError) {
          showSnackBar(context, translateError(context, state.error!.code));
        }
      },
      child: BlocConsumer<ConnectivityCubit, ConnectivityState>(
        //Only re-initialize data if the connectivity changed from not connected to connected
        listenWhen: (previous, current) =>
            current == ConnectivityState.connected,
        listener: (context, state) {
          initializeLabelData(context);
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
              MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: getIt<DocumentsCubit>()),
                ],
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
      ),
    );
  }

  initializeLabelData(BuildContext context) {
    BlocProvider.of<DocumentTypeCubit>(context).initialize();
    BlocProvider.of<CorrespondentCubit>(context).initialize();
    BlocProvider.of<TagCubit>(context).initialize();
    BlocProvider.of<StoragePathCubit>(context).initialize();
    BlocProvider.of<SavedViewCubit>(context).initialize();
  }
}
