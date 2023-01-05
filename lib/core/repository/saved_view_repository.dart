import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/base_repository.dart';

abstract class SavedViewRepository
    implements BaseRepository<Map<int, SavedView>, SavedView> {}
