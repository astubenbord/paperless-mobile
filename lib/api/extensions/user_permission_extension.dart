import 'package:paperless_mobile/api/paperless_api.dart';

extension UserPermissionExtension on UiSettingsView {
  bool hasPermission(PermissionAction action, PermissionTarget target) {
    if (user.isSuperuser ?? false) {
      return true;
    }
    final permission = [action.value, target.value].join("_");

    return (permissions?.any((p) => p == permission) ?? false);
  }

  bool hasPermissions(
    List<PermissionAction> actions,
    List<PermissionTarget> targets,
  ) {
    if (user.isSuperuser ?? false) {
      return true;
    }
    final permissions = [
      for (var action in actions)
        for (var target in targets) [action, target].join("_"),
    ];
    return permissions.every((p) => permissions.contains(p));
  }

  bool get canViewDocuments =>
      hasPermission(PermissionAction.view, PermissionTarget.document);
  bool get canViewCorrespondents =>
      hasPermission(PermissionAction.view, PermissionTarget.correspondent);
  bool get canViewDocumentTypes =>
      hasPermission(PermissionAction.view, PermissionTarget.documentType);
  bool get canViewTags =>
      hasPermission(PermissionAction.view, PermissionTarget.tag);
  bool get canViewStoragePaths =>
      hasPermission(PermissionAction.view, PermissionTarget.storagePath);
  bool get canViewSavedViews =>
      hasPermission(PermissionAction.view, PermissionTarget.savedView);

  bool get canEditDocuments =>
      hasPermission(PermissionAction.change, PermissionTarget.document);
  bool get canEditCorrespondents =>
      hasPermission(PermissionAction.change, PermissionTarget.correspondent);
  bool get canEditDocumentTypes =>
      hasPermission(PermissionAction.change, PermissionTarget.documentType);
  bool get canEditTags =>
      hasPermission(PermissionAction.change, PermissionTarget.tag);
  bool get canEditStoragePaths =>
      hasPermission(PermissionAction.change, PermissionTarget.storagePath);
  bool get canEditavedViews =>
      hasPermission(PermissionAction.change, PermissionTarget.savedView);

  bool get canDeleteDocuments =>
      hasPermission(PermissionAction.delete, PermissionTarget.document);
  bool get canDeleteCorrespondents =>
      hasPermission(PermissionAction.delete, PermissionTarget.correspondent);
  bool get canDeleteDocumentTypes =>
      hasPermission(PermissionAction.delete, PermissionTarget.documentType);
  bool get canDeleteTags =>
      hasPermission(PermissionAction.delete, PermissionTarget.tag);
  bool get canDeleteStoragePaths =>
      hasPermission(PermissionAction.delete, PermissionTarget.storagePath);
  bool get canDeleteSavedViews =>
      hasPermission(PermissionAction.delete, PermissionTarget.savedView);

  bool get canCreateDocuments =>
      hasPermission(PermissionAction.add, PermissionTarget.document);
  bool get canCreateCorrespondents =>
      hasPermission(PermissionAction.add, PermissionTarget.correspondent);
  bool get canCreateDocumentTypes =>
      hasPermission(PermissionAction.add, PermissionTarget.documentType);
  bool get canCreateTags =>
      hasPermission(PermissionAction.add, PermissionTarget.tag);
  bool get canCreateStoragePaths =>
      hasPermission(PermissionAction.add, PermissionTarget.storagePath);
  bool get canCreateSavedViews =>
      hasPermission(PermissionAction.add, PermissionTarget.savedView);

  bool get canViewCustomFields =>
      hasPermission(PermissionAction.view, PermissionTarget.customField);
  bool get canEditCustomFields =>
      hasPermission(PermissionAction.change, PermissionTarget.customField);
  bool get canDeleteCustomFields =>
      hasPermission(PermissionAction.delete, PermissionTarget.customField);
  bool get canCreateCustomFields =>
      hasPermission(PermissionAction.add, PermissionTarget.customField);

  bool get canViewAnyLabel =>
      canViewCorrespondents ||
      canViewDocumentTypes ||
      canViewTags ||
      canViewStoragePaths;

  bool get canViewInbox => canViewTags && canViewDocuments;

  bool get canUseDocumentChat =>
      (settings?.aiEnabled ?? false) && canViewDocuments;
}
