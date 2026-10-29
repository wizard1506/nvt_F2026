import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../utils/fechas.dart';
import 'reporte_service.dart';

class ReporteExcelService {
  ReporteExcelService._();

  static Uint8List prospectos(List<ReporteProspecto> filas) {
    return _crearLibro(
      nombreHoja: 'Prospectos',
      encabezados: const [
        'ID',
        'Fecha registro',
        'Vigencia',
        'Prospecto',
        'Teléfono',
        'Origen del prospecto',
        'Información',
        'Nombre completo del usuario',
        'Usuario',
      ],
      filas: [
        for (final fila in filas)
          [
            fila.id,
            _fechaHora(fila.createdAt),
            dmaDesdeIso(fila.vigencia),
            fila.prospecto,
            fila.telefono,
            fila.origenProspecto,
            fila.informacion,
            fila.nombreCompletoRegistrador,
            fila.usuarioRegistrador,
          ],
      ],
      anchos: const [8, 20, 12, 28, 15, 24, 50, 36, 18],
      columnaInformacion: 6,
    );
  }

  static Uint8List citas(List<ReporteCita> filas) {
    return _crearLibro(
      nombreHoja: 'Citas',
      encabezados: const [
        'ID',
        'Fecha registro',
        'Contrato',
        'Cliente',
        'Fecha cita',
        'Hora cita',
        'Estado',
        'Información',
        'Nombre completo del usuario',
        'Usuario',
      ],
      filas: [
        for (final fila in filas)
          [
            fila.id,
            _fechaHora(fila.createdAt),
            fila.contrato,
            fila.cliente,
            dmaDesdeIso(fila.fechaCita),
            fila.horaCita,
            fila.estado,
            fila.informacion,
            fila.nombreCompletoRegistrador,
            fila.usuarioRegistrador,
          ],
      ],
      anchos: const [8, 20, 18, 34, 12, 10, 15, 50, 36, 18],
      columnaInformacion: 7,
    );
  }

  static Uint8List _crearLibro({
    required String nombreHoja,
    required List<String> encabezados,
    required List<List<Object?>> filas,
    required List<double> anchos,
    required int columnaInformacion,
  }) {
    final ultimaColumna = _letraColumna(encabezados.length - 1);
    final ultimaFila = filas.length + 1;

    final hoja = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
      )
      ..write('<dimension ref="A1:$ultimaColumna$ultimaFila"/>')
      ..write(
        '<sheetViews><sheetView workbookViewId="0">'
        '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
        '</sheetView></sheetViews>',
      )
      ..write('<sheetFormatPr defaultRowHeight="15"/>')
      ..write('<cols>');

    for (var i = 0; i < anchos.length; i++) {
      final numero = i + 1;
      hoja.write(
        '<col min="$numero" max="$numero" width="${anchos[i]}" customWidth="1"/>',
      );
    }

    hoja
      ..write('</cols><sheetData>')
      ..write('<row r="1" ht="22" customHeight="1">');

    for (var i = 0; i < encabezados.length; i++) {
      hoja.write(_celda('${_letraColumna(i)}1', encabezados[i], estilo: 1));
    }

    hoja.write('</row>');

    for (var f = 0; f < filas.length; f++) {
      final numeroFila = f + 2;
      hoja.write('<row r="$numeroFila">');
      for (var c = 0; c < filas[f].length; c++) {
        hoja.write(
          _celda(
            '${_letraColumna(c)}$numeroFila',
            filas[f][c],
            estilo: c == columnaInformacion ? 2 : null,
          ),
        );
      }
      hoja.write('</row>');
    }

    hoja
      ..write('</sheetData>')
      ..write('<autoFilter ref="A1:$ultimaColumna$ultimaFila"/>')
      ..write('</worksheet>');

    final archivos = <ArchiveFile>[
      ArchiveFile.string('[Content_Types].xml', _contentTypes),
      ArchiveFile.string('_rels/.rels', _relsRaiz),
      ArchiveFile.string('docProps/core.xml', _coreProperties),
      ArchiveFile.string('docProps/app.xml', _appProperties),
      ArchiveFile.string('xl/workbook.xml', _workbook(nombreHoja)),
      ArchiveFile.string('xl/_rels/workbook.xml.rels', _relsWorkbook),
      ArchiveFile.string('xl/styles.xml', _styles),
      ArchiveFile.string('xl/worksheets/sheet1.xml', hoja.toString()),
    ];

    final archivo = Archive();
    for (final item in archivos) {
      archivo.addFile(item);
    }

    return Uint8List.fromList(ZipEncoder().encode(archivo));
  }

  static String _fechaHora(DateTime? fecha) {
    if (fecha == null) return '';
    final dia = _dosDigitos(fecha.day);
    final mes = _dosDigitos(fecha.month);
    final hora = _dosDigitos(fecha.hour);
    final minuto = _dosDigitos(fecha.minute);
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  static String _dosDigitos(int valor) => valor.toString().padLeft(2, '0');

  static String _letraColumna(int indice) {
    var numero = indice + 1;
    var letra = '';
    while (numero > 0) {
      final resto = (numero - 1) % 26;
      letra = String.fromCharCode(65 + resto) + letra;
      numero = (numero - 1) ~/ 26;
    }
    return letra;
  }

  static String _celda(String referencia, Object? valor, {int? estilo}) {
    final atributoEstilo = estilo == null ? '' : ' s="$estilo"';
    if (valor is num) {
      return '<c r="$referencia"$atributoEstilo><v>$valor</v></c>';
    }
    final texto = _escaparXml('${valor ?? ''}');
    return '<c r="$referencia"$atributoEstilo t="inlineStr">'
        '<is><t xml:space="preserve">$texto</t></is></c>';
  }

  static String _escaparXml(String valor) {
    final limpio = valor.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
      '',
    );
    return limpio
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\n', '&#10;')
        .replaceAll('\t', '&#9;');
  }

  static String _workbook(String nombreHoja) {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets><sheet name="${_escaparXml(nombreHoja)}" sheetId="1" r:id="rId1"/>'
        '</sheets></workbook>';
  }

  static const String _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
      '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
      '</Types>';

  static const String _relsRaiz =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
      '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>'
      '</Relationships>';

  static const String _relsWorkbook =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';

  static const String _coreProperties =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/" '
      'xmlns:dcterms="http://purl.org/dc/terms/" '
      'xmlns:dcmitype="http://purl.org/dc/dcmitype/" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
      '<dc:creator>Novitierra</dc:creator>'
      '<cp:lastModifiedBy>Novitierra</cp:lastModifiedBy>'
      '</cp:coreProperties>';

  static const String _appProperties =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" '
      'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">'
      '<Application>Novitierra</Application>'
      '</Properties>';

  static const String _styles =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="2">'
      '<font><sz val="11"/><name val="Calibri"/><family val="2"/></font>'
      '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/><family val="2"/></font>'
      '</fonts>'
      '<fills count="3">'
      '<fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FF0D3B66"/><bgColor indexed="64"/></patternFill></fill>'
      '</fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="3">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>'
      '</cellXfs>'
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
      '</styleSheet>';
}
