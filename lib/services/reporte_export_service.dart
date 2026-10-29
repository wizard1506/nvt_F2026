import 'dart:ui';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

class ReporteExportService {
  ReporteExportService._();

  static final ReporteExportService instance = ReporteExportService._();

  static const String mimeExcel =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  bool get puedeCompartir {
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.linux;
  }

  Future<String?> descargar({
    required String nombre,
    required Uint8List bytes,
  }) async {
    try {
      return await FileSaver.instance.saveToDownloads(
        name: nombre,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
        subfolder: 'Reportes',
      );
    } catch (_) {
      return FileSaver.instance.saveAs(
        name: nombre,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
        dialogTitle: 'Guardar reporte',
      );
    }
  }

  Future<ShareResult> compartir({
    required String nombre,
    required Uint8List bytes,
    Rect? origen,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeExcel)],
        fileNameOverrides: ['$nombre.xlsx'],
        subject: nombre,
        title: nombre,
        sharePositionOrigin: origen,
      ),
    );
  }
}
