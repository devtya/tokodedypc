import 'package:injectable/injectable.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

class UpdateInfo {
  final String version;
  final String url;
  final String? notes;
  final String? assetName;

  UpdateInfo({required this.version, required this.url, this.notes, this.assetName});
}

@lazySingleton
class UpdateService {
  String repoOwner = 'devtya';
  String repoName = 'tokodedypc';
  static const String _assetName = 'tokodedypc-windows.zip';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final uri = Uri.parse(
        'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceAll('v', '');
      final body = json['body'] as String?;

      if (_compareVersions(latestVersion, currentVersion) <= 0) return null;

      final assets = json['assets'] as List<dynamic>? ?? [];
      String? downloadUrl;
      String? foundAssetName;

      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        final lowerName = name.toLowerCase();
        // Look for .zip file since windows release packages it as zip
        if (lowerName.endsWith('.zip')) {
          downloadUrl = asset['browser_download_url'] as String?;
          foundAssetName = name;
          break;
        }
      }

      if (downloadUrl == null) return null;

      return UpdateInfo(
        version: latestVersion,
        url: downloadUrl,
        notes: body,
        assetName: foundAssetName,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> downloadUpdate(
    String url, {
    String? assetName,
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final fileName = assetName ?? _assetName;
    final file = File('${dir.path}/$fileName');

    final response = await http.Client().send(http.Request('GET', Uri.parse(url)));
    final total = response.contentLength ?? 0;
    var downloaded = 0;

    final sink = file.openWrite(mode: FileMode.write);
    await for (final chunk in response.stream) {
      sink.add(chunk);
      downloaded += chunk.length;
      if (total > 0) {
        onProgress?.call(downloaded / total);
      }
    }
    await sink.close();

    return file.path;
  }

  Future<void> installUpdate(String zipPath) async {
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory('${tempDir.path}\\TokoDedyUpdate');
    
    if (extractDir.existsSync()) {
      extractDir.deleteSync(recursive: true);
    }
    extractDir.createSync();

    // Extract zip
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File('${extractDir.path}\\$filename')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory('${extractDir.path}\\$filename').createSync(recursive: true);
      }
    }

    // Create update.bat
    final exePath = Platform.resolvedExecutable;
    final appDir = File(exePath).parent.path;
    final exeName = exePath.split(Platform.pathSeparator).last;
    
    final batPath = '${tempDir.path}\\update_tokodedy.bat';
    final batFile = File(batPath);
    final script = '''
@echo off
echo Menginstal pembaruan Toko Dedy... Mohon tunggu sebentar.

:WAITLOOP
timeout /t 1 /nobreak > NUL
tasklist | find /i "$exeName" > NUL
if not errorlevel 1 goto WAITLOOP

xcopy /s /e /y "${extractDir.path}\\*" "$appDir\\"
cd /d "$appDir"
start "" "$exeName" < NUL > NUL 2>&1
exit
'''.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n');
    batFile.writeAsStringSync(script);

    // Execute bat detached and exit app
    await Process.start('cmd.exe', ['/c', 'start', 'cmd.exe', '/c', batPath], mode: ProcessStartMode.detached);
    exit(0);
  }

  List<int> _extractVersion(String versionString) {
    final RegExp regex = RegExp(r'(\d+)\.(\d+)\.(\d+)(?:[\+_\-](\d+))?');
    final match = regex.firstMatch(versionString);
    if (match != null) {
      final major = int.parse(match.group(1)!);
      final minor = int.parse(match.group(2)!);
      final patch = int.parse(match.group(3)!);
      final build = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      return [major, minor, patch, build];
    }
    return [0, 0, 0, 0];
  }

  int _compareVersions(String a, String b) {
    final partsA = _extractVersion(a);
    final partsB = _extractVersion(b);
    
    for (var i = 0; i < partsA.length; i++) {
      if (partsA[i] != partsB[i]) {
        return partsA[i] - partsB[i];
      }
    }
    return 0;
  }
}
