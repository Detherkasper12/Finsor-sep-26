import 'dart:html' as html;

Future<void> saveBackupPlatform(String json, String filename) async {
  final blob = html.Blob([json]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
}
