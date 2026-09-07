import 'dart:typed_data';
import 'export_strategy.dart';

/// XLSX export – not implemented yet.
class XlsxExportStrategy implements ExportStrategy {
  @override
  Future<ExportResult> generate(ExportPayload payload) async {
    throw UnimplementedError('XLSX export is not implemented');
  }
}
