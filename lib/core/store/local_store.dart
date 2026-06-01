import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/store/local_store_state_v1.dart';
import 'package:paperless_mobile/core/store/local_store_state_v2.dart';
import 'package:paperless_mobile/core/store/slices/global_settings.dart';
import 'package:paperless_mobile/core/store/slices/local_user_app_state.dart';
import 'package:paperless_mobile/core/store/slices/local_user_data.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';

part 'local_store.g.dart';
part 'local_store_state.dart';

typedef Updater<T> = T Function(T);

class LocalStore extends HydratedCubit<LocalStoreState> {
  LocalStore(String defaultPreferredLocaleSubtag)
    : super(
        LocalStoreState(
          globalSettings: GlobalSettings(
            preferredLocaleSubtag: defaultPreferredLocaleSubtag,
          ),
        ),
      );

  void acknowledgeHint(String hintKey) {
    if (!state.readHints.contains(hintKey)) {
      final updatedHints = List<String>.from(state.readHints)..add(hintKey);
      emit(state.copyWith(readHints: updatedHints));
    }
  }

  void updateCurrentDocumentFilter(Updater<DocumentFilter> updater) {
    updateLoggedInUserAppState(
      (appState) => appState.copyWith(
        currentDocumentFilter: updater(appState.currentDocumentFilter),
      ),
    );
  }

  void setLoggedInAppUserId(String? userId) {
    emit(state.copyWith(loggedInAppUserId: userId));
  }

  void updateGlobalSettings(Updater<GlobalSettings> updater) {
    emit(state.copyWith(globalSettings: updater(state.globalSettings)));
  }

  void updateLoggedInUserAppState(Updater<LocalUserAppState> updater) {
    if (state.loggedInAppUserId == null) {
      logger.fw(
        'could not update app state of logged in user because no user is logged in',
        className: runtimeType.toString(),
        methodName: 'updateLoggedInUserAppState',
      );
      return;
    }
    updateUserData(state.loggedInAppUserId!, (userData) {
      final updated = userData.copyWith(appState: updater(userData.appState));
      return updated;
    });
  }

  void updateLoggedInUserData(Updater<LocalUserData> updater) {
    if (state.loggedInAppUserId == null) {
      logger.fw(
        'could not update data of logged in user because no user is logged in',
        className: runtimeType.toString(),
        methodName: 'updateLoggedInUserData',
      );
      return;
    }
    updateUserData(state.loggedInAppUserId!, updater);
  }

  void setUserData(String userId, LocalUserData userData) {
    emit(
      state.copyWith(localUserData: {...state.localUserData, userId: userData}),
    );
  }

  void updateUserData(String userId, Updater<LocalUserData> updater) {
    if (!state.localUserData.containsKey(userId)) {
      logger.fw(
        'could not update user data for userId=$userId because no such user data exists',
        className: runtimeType.toString(),
        methodName: 'updateUserData',
      );
      return;
    }
    emit(
      state.copyWith(
        localUserData: {
          ...state.localUserData,
          userId: updater(state.localUserData[userId]!),
        },
      ),
    );
  }

  void removeUserData(String userId) {
    final newUserData = {...state.localUserData};
    newUserData.remove(userId);
    emit(state.copyWith(localUserData: newUserData));
  }

  @override
  LocalStoreState? fromJson(Map<String, dynamic> json) {
    return LocalStoreState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(LocalStoreState state) => state.toJson();
}
