import 'dart:typed_data';
import 'export_strategy.dart';

/// PDF export – not implemented yet.
class PdfExportStrategy implements ExportStrategy {
  @override
  Future<ExportResult> generate(ExportPayload payload) async {
    throw UnimplementedError('PDF export is not implemented');
  }
}
