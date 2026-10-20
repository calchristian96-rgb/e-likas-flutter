import 'dart:io';

import 'package:open_filex/open_filex.dart';

abstract class ApkInstaller {
  /// Hands [apk] to the Android package installer. True when the system
  /// installer UI was launched; false when it could not be. Android
  /// itself shows the "install unknown apps" prompt the first time and
  /// enforces that the update is signed with the installed app's key.
  Future<bool> install(File apk);
}

class OpenFilexApkInstaller implements ApkInstaller {
  const OpenFilexApkInstaller();

  static const _apkMimeType = 'application/vnd.android.package-archive';

  @override
  Future<bool> install(File apk) async {
    try {
      final result = await OpenFilex.open(apk.path, type: _apkMimeType);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }
}
