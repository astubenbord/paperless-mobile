import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_cubit.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/pages/documents_page.dart';
import 'package:paperless_mobile/features/home/view/widget/bottom_navigation_bar.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/labels/view/pages/labels_page.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
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
  final DocumentScannerCubit _scannerCubit = DocumentScannerCubit();
  @override
  void initState() {
    super.initState();
    _initializeData(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      //Only re-initialize data if the connectivity changed from not connected to connected
      listenWhen: (previous, current) => current == ConnectivityState.connected,
      listener: (context, state) {
        _initializeData(context);
      },
      child: Scaffold(
        key: rootScaffoldKey,
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _currentIndex,
          onNavigationChanged: (index) {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
          },
        ),
        drawer: const InfoDrawer(),
        body: [
          MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: DocumentsCubit(getIt<PaperlessDocumentsApi>()),
              ),
              BlocProvider(
                create: (context) => SavedViewCubit(
                  RepositoryProvider.of<SavedViewRepository>(context),
                ),
              ),
            ],
            child: const DocumentsPage(),
          ),
          BlocProvider.value(
            value: _scannerCubit,
            child: const ScannerPage(),
          ),
          BlocProvider.value(
            value: DocumentsCubit(getIt<PaperlessDocumentsApi>()),
            child: const LabelsPage(),
          ),
        ][_currentIndex],
      ),
    );
  }

  void _initializeData(BuildContext context) {
    try {
      RepositoryProvider.of<LabelRepository<Tag>>(context).findAll();
      RepositoryProvider.of<LabelRepository<Correspondent>>(context).findAll();
      RepositoryProvider.of<LabelRepository<DocumentType>>(context).findAll();
      RepositoryProvider.of<LabelRepository<StoragePath>>(context).findAll();
      RepositoryProvider.of<SavedViewRepository>(context).findAll();
      BlocProvider.of<PaperlessServerInformationCubit>(context)
          .updateInformtion();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
