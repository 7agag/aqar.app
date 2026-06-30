import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionService {
  AppPermissionService._();

  static bool _requestedStartupPermissions = false;

  static Future<Map<Permission, PermissionStatus>>
      requestStartupPermissions() async {
    if (_requestedStartupPermissions) {
      return _readStatuses(_startupPermissions);
    }

    _requestedStartupPermissions = true;
    return requestPermissions(_startupPermissions);
  }

  static Future<Map<Permission, PermissionStatus>> requestPermissions(
    Iterable<Permission> permissions,
  ) async {
    final uniquePermissions = permissions.toSet();
    final statuses = <Permission, PermissionStatus>{};

    try {
      for (final permission in uniquePermissions) {
        final status = await permission.status;
        statuses[permission] = status;
      }

      final permissionsToRequest = statuses.entries
          .where((entry) => _shouldRequest(entry.value))
          .map((entry) => entry.key)
          .toList(growable: false);

      if (permissionsToRequest.isEmpty) {
        return statuses;
      }

      final requestedStatuses = await permissionsToRequest.request();
      statuses.addAll(requestedStatuses);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to request app permissions',
        name: 'AppPermissionService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return statuses;
  }

  static Future<Map<Permission, PermissionStatus>> _readStatuses(
    Iterable<Permission> permissions,
  ) async {
    final statuses = <Permission, PermissionStatus>{};

    try {
      for (final permission in permissions.toSet()) {
        statuses[permission] = await permission.status;
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to read app permission statuses',
        name: 'AppPermissionService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return statuses;
  }

  static bool _shouldRequest(PermissionStatus status) {
    return !status.isGranted &&
        !status.isLimited &&
        !status.isPermanentlyDenied &&
        !status.isRestricted;
  }

  static List<Permission> get _startupPermissions {
    if (kIsWeb) {
      return const [];
    }

    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.camera,
    ];

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        permissions.addAll([
          Permission.photos,
          Permission.storage,
        ]);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        permissions.add(Permission.photos);
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
    }

    return permissions;
  }
}
