import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveBackupPlatform(String json, String filename) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$filename';
  await File(path).writeAsString(json);
  await Share.shareXFiles([XFile(path)], text: 'Finsor backup');
}
