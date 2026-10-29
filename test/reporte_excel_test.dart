import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novitierra_f/services/reporte_excel_service.dart';
import 'package:novitierra_f/services/reporte_service.dart';

void main() {
  test('El Excel de prospectos incluye datos y usuario registrador', () {
    final bytes = ReporteExcelService.prospectos([
      ReporteProspecto(
        id: 7,
        createdAt: DateTime(2026, 10, 5, 14, 30),
        prospecto: 'MARIA LOPEZ',
        telefono: '77712345',
        origenProspecto: 'WhatsApp',
        informacion: 'Interesada\nLlamar por la tarde',
        vigencia: '2026-11-05',
        nombreCompletoRegistrador: 'ANDRES JIMENEZ',
        usuarioRegistrador: 'ajc',
      ),
    ]);

    final hoja = _hoja(bytes);
    expect(hoja, contains('Nombre completo del usuario'));
    expect(hoja, contains('Fecha registro'));
    expect(hoja, contains('05/10/2026 14:30'));
    expect(hoja, contains('05/11/2026'));
    expect(hoja, contains('MARIA LOPEZ'));
    expect(hoja, contains('77712345'));
    expect(hoja, contains('ANDRES JIMENEZ'));
    expect(hoja, contains('ajc'));
    expect(hoja, contains('Interesada&#10;Llamar por la tarde'));
  });

  test('El Excel de citas incluye datos y usuario registrador', () {
    final bytes = ReporteExcelService.citas([
      ReporteCita(
        id: 12,
        createdAt: DateTime(2026, 10, 6, 9, 5),
        contrato: 'CT-0012',
        cliente: 'JUAN PEREZ',
        fechaCita: '2026-10-20',
        horaCita: '16:30',
        informacion: 'Confirmar asistencia',
        estado: 'PENDIENTE',
        nombreCompletoRegistrador: 'MARIANA CUEVAS',
        usuarioRegistrador: 'MCUEVAS',
      ),
    ]);

    final hoja = _hoja(bytes);
    expect(hoja, contains('Nombre completo del usuario'));
    expect(hoja, contains('06/10/2026 09:05'));
    expect(hoja, contains('CT-0012'));
    expect(hoja, contains('JUAN PEREZ'));
    expect(hoja, contains('20/10/2026'));
    expect(hoja, contains('16:30'));
    expect(hoja, contains('PENDIENTE'));
    expect(hoja, contains('MARIANA CUEVAS'));
    expect(hoja, contains('MCUEVAS'));
  });

  test('El libro contiene las partes necesarias de un xlsx', () {
    final bytes = ReporteExcelService.prospectos(const []);
    final archivo = ZipDecoder().decodeBytes(bytes);
    final nombres = archivo.files.map((file) => file.name).toSet();

    expect(nombres, contains('[Content_Types].xml'));
    expect(nombres, contains('_rels/.rels'));
    expect(nombres, contains('xl/workbook.xml'));
    expect(nombres, contains('xl/styles.xml'));
    expect(nombres, contains('xl/worksheets/sheet1.xml'));

    final workbook = archivo.files.firstWhere(
      (file) => file.name == 'xl/workbook.xml',
    );
    expect(utf8.decode(workbook.readBytes()!), contains('name="Prospectos"'));
  });
}

String _hoja(List<int> bytes) {
  final archivo = ZipDecoder().decodeBytes(bytes);
  final hoja = archivo.files.firstWhere(
    (file) => file.name == 'xl/worksheets/sheet1.xml',
  );
  return utf8.decode(hoja.readBytes()!);
}
