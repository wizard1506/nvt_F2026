import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class GeneratedForm {
  const GeneratedForm({required this.bytes, required this.path});

  final Uint8List bytes;
  final String path;
}

class FormGeneratorService {
  static const double _imageWidth = 1700;
  static const double _imageHeight = 2800;
  static const double _pageWidthPt = 612.0;
  static const double _pageHeightPt = _pageWidthPt * _imageHeight / _imageWidth;
  static const double _reservaWidth = 2150;
  static const double _reservaHeight = 3280;
  static const double _reservaPageHeight =
      _pageWidthPt * _reservaHeight / _reservaWidth;
  static const double _cssPageWidth = 684.0;
  static const double _cssToPage = _pageWidthPt / _cssPageWidth;
  static const double _nativeToPt = _pageWidthPt / _imageWidth;
  static const double _nativeAdjustX = 10.0;
  static const double _nativeAdjustY = 10.0;
  static const double _cssFontToPt = 72 / 96;
  static const double _downscaleWidth = 1275;
  static const double _downscaleHeight = 2100;
  static const double _reservaDownscaleWidth = 1612;
  static const double _reservaDownscaleHeight = 2460;
  static const double _form4Width = 2480;
  static const double _form4Height = 3780;
  static const double _form4PageHeight =
      _pageWidthPt * _form4Height / _form4Width;
  static const double _form4DownscaleWidth = 2480;
  static const double _form4DownscaleHeight = 3780;
  static const double _form4NativeToPt = _pageWidthPt / _form4Width;
  static const double _form4FontSize = 12;
  static const double _form4CheckSize = 40.0;
  static const double _mapaBoxLeft = 98;
  static const double _mapaBoxTop = 642;
  static const double _mapaBoxWidth = 1521;
  static const double _mapaBoxHeight = 1822;
  static const double _mapaImageMax = 1200;

  static const String _sampleAsset = 'assets/images/datos/cliente.txt';
  static const String _form1Asset = 'assets/images/f1.png';
  static const String _form3Asset = 'assets/images/f3.png';
  static const String _form4Asset = 'assets/images/nuevof4.jpg';
  static const String _reservaAsset = 'assets/images/reserva.png';
  static const String _mapaAsset = 'assets/images/mapa.png';
  static const String _cosolAsset = 'assets/images/cosol.png';
  static const String _checkAsset = 'assets/images/check1.jpg';
  static const String _fontRegularAsset = 'assets/fonts/FiraSans-Regular.ttf';
  static const double _checkSize = 50.0;

  Future<Map<String, String>> loadSampleData() async {
    final raw = await rootBundle.load(_sampleAsset);
    return _parse(utf8.decode(raw.buffer.asUint8List()));
  }

  Future<GeneratedForm> generateFromSample() async {
    final data = await loadSampleData();
    return generateAndSave(data);
  }

  Future<GeneratedForm> generateAndSave(
    Map<String, String> data, {
    Uint8List? mapaImagen,
  }) async {
    final bytes = await generatePdf(data, mapaImagen: mapaImagen);
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}${Platform.pathSeparator}Novitierra');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final file = File(
      '${folder.path}${Platform.pathSeparator}novitierra_formulario_$stamp.pdf',
    );
    await file.writeAsBytes(bytes);
    return GeneratedForm(bytes: bytes, path: file.path);
  }

  Future<Uint8List> generatePdf(
    Map<String, String> data, {
    Uint8List? mapaImagen,
  }) async {
    final font = await _loadFont(_fontRegularAsset);
    final check = await _loadImage(_checkAsset);
    final pages = <(PdfPageFormat, pw.Widget)>[
      (
        PdfPageFormat(_pageWidthPt, _pageHeightPt),
        _buildPage(
          await _downscalePng(_form1Asset),
          _form1Fields(data, check),
          font,
        ),
      ),
      (
        PdfPageFormat(_pageWidthPt, _pageHeightPt),
        _buildPage(await _downscalePng(_form3Asset), _form3Fields(data), font),
      ),
      (
        PdfPageFormat(_pageWidthPt, _form4PageHeight),
        _buildPage(
          await _downscalePng(
            _form4Asset,
            width: _form4DownscaleWidth,
            height: _form4DownscaleHeight,
          ),
          _form4Fields(data, check),
          font,
          nativeFactor: _form4NativeToPt,
        ),
      ),
      if (mapaImagen != null)
        (
          PdfPageFormat(_pageWidthPt, _pageHeightPt),
          _buildPage(await _downscalePng(_mapaAsset), [
            _mapaBoxOverlay(await _downscaleToMax(mapaImagen, _mapaImageMax)),
            ..._mapaFields(data),
          ], font),
        ),
      if (data['generar_reserva'] == 'SI')
        (
          PdfPageFormat(_pageWidthPt, _reservaPageHeight),
          _buildPage(
            await _downscalePng(
              _reservaAsset,
              width: _reservaDownscaleWidth,
              height: _reservaDownscaleHeight,
            ),
            _reservaFields(data),
            font,
            nativeFactor: _pageWidthPt / _reservaWidth,
          ),
        ),
    ];

    final doc = pw.Document();
    for (final (format, page) in pages) {
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (context) => page,
        ),
      );
    }
    return doc.save();
  }

  Future<GeneratedForm> generateCosolAndSave(Map<String, String> data) async {
    final bytes = await generateCosolPdf(data);
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}${Platform.pathSeparator}Novitierra');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final file = File(
      '${folder.path}${Platform.pathSeparator}novitierra_cosol_$stamp.pdf',
    );
    await file.writeAsBytes(bytes);
    return GeneratedForm(bytes: bytes, path: file.path);
  }

  Future<Uint8List> generateCosolPdf(Map<String, String> data) async {
    final font = await _loadFont(_fontRegularAsset);
    final cosol = await _downscalePng(_cosolAsset);
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_pageWidthPt, _pageHeightPt),
        margin: pw.EdgeInsets.zero,
        build: (context) => _buildPage(cosol, _cosolFields(data), font),
      ),
    );
    return doc.save();
  }

  Future<pw.Font> _loadFont(String asset) async {
    final data = await rootBundle.load(asset);
    return pw.Font.ttf(data);
  }

  Future<Uint8List> _loadImage(String asset) async {
    final data = await rootBundle.load(asset);
    return data.buffer.asUint8List();
  }

  Future<Uint8List> _downscalePng(
    String asset, {
    double width = _downscaleWidth,
    double height = _downscaleHeight,
  }) async {
    final raw = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(raw.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      src,
      ui.Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    src.dispose();
    img.dispose();
    return bytes!.buffer.asUint8List();
  }

  pw.Widget _buildPage(
    Uint8List backgroundBytes,
    List<_Overlay> fields,
    pw.Font font, {
    double nativeFactor = _nativeToPt,
  }) {
    return pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Image(pw.MemoryImage(backgroundBytes), fit: pw.BoxFit.fill),
        ),
        for (final f in fields)
          if (f.qr != null)
            pw.Positioned(
              left: f.left * nativeFactor,
              top: f.top * nativeFactor,
              child: pw.Container(
                width: f.width! * nativeFactor,
                height: f.height! * nativeFactor,
                color: PdfColors.white,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(6),
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: f.qr!,
                  width: (f.width! - 12) * nativeFactor,
                  height: (f.height! - 12) * nativeFactor,
                ),
              ),
            )
          else if (f.imageBox != null)
            pw.Positioned(
              left: f.left * nativeFactor,
              top: f.top * nativeFactor,
              child: pw.SizedBox(
                width: f.width! * nativeFactor,
                height: f.height! * nativeFactor,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey700, width: 1.2),
                  ),
                  child: pw.Image(
                    pw.MemoryImage(f.imageBox!),
                    fit: pw.BoxFit.fill,
                  ),
                ),
              ),
            )
          else if (f.image != null)
            pw.Positioned(
              left: (f.left - f.imageSize! / 2) * nativeFactor,
              top: (f.top - f.imageSize! / 2) * nativeFactor,
              child: pw.Image(
                pw.MemoryImage(f.image!),
                width: f.imageSize! * nativeFactor,
                height: f.imageSize! * nativeFactor,
              ),
            )
          else if (f.ringSize != null)
            pw.Positioned(
              left: (f.left - f.ringSize! / 2) * nativeFactor,
              top: (f.top - f.ringSize! / 2) * nativeFactor,
              child: pw.Container(
                width: f.ringSize! * nativeFactor,
                height: f.ringSize! * nativeFactor,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(
                    color: PdfColors.black,
                    width: f.ringStroke ?? 2.0,
                  ),
                ),
              ),
            )
          else if (f.text.isNotEmpty)
            pw.Positioned(
              left: f.center
                  ? (f.left - f.width! / 2) * _factor(f, nativeFactor)
                  : f.native
                  ? (f.left - _nativeAdjustX) * nativeFactor
                  : f.left * _cssToPage,
              top: f.center
                  ? f.top * _factor(f, nativeFactor) -
                        f.fontSize * _cssFontToPt * 0.6
                  : f.native
                  ? (f.top - _nativeAdjustY) * nativeFactor
                  : f.top * _cssToPage,
              child: pw.SizedBox(
                width: f.width == null
                    ? null
                    : f.width! * _factor(f, nativeFactor),
                child: pw.Text(
                  f.text,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: f.fontSize * _cssFontToPt,
                  ),
                  textAlign: f.center ? pw.TextAlign.center : pw.TextAlign.left,
                ),
              ),
            ),
      ],
    );
  }

  double _factor(_Overlay f, double nativeFactor) {
    return f.native ? nativeFactor : _cssToPage;
  }

  List<_Overlay> _form1Fields(Map<String, String> d, Uint8List check) {
    final _Overlay? checkOverlay = switch (d['plazo_contado']) {
      'PLAZO' => _check(698.5, 499.5, check),
      'CONTADO' => _check(1000.5, 500.5, check),
      _ => null,
    };

    return <_Overlay>[
      ?checkOverlay,
      _text(638.6, 208.6, d['urbanizacion'] ?? '', native: true),
      _text(410.6, 318.6, _fullName(d), native: true),
      _text(500.6, 407.6, d['documento'] ?? '', native: true),
      _text(1010, 407.6, d['extension'] ?? '', native: true),
      _text(296.6, 590.6, d['proyecto'] ?? '', native: true),
      _text(599.6, 590.6, d['uv'] ?? '', native: true),
      _text(912.6, 590.6, d['mz'] ?? '', native: true),
      _text(1188.6, 590.6, d['lt'] ?? '', native: true),
      _text(1510.6, 590.6, d['cat'] ?? '', native: true),
      _text(
        534,
        705,
        _join([d['user_nombres'], d['user_apellidos']]),
        width: 800,
        center: true,
        native: true,
      ),
      _text(
        1372,
        705,
        d['user_codigo_asesor'] ?? '',
        width: 300,
        center: true,
        native: true,
      ),
    ];
  }

  List<_Overlay> _form3Fields(Map<String, String> d) {
    final dia = _dateValue(d['dia']);
    final mes = _dateValue(d['mes']);
    final anio = _dateValue(d['anio']);
    final nombreCompleto = _fullName(d);

    return <_Overlay>[
      _text(170.6, 381.6, dia, fontSize: 16, native: true),
      _text(325.6, 381.6, mes, fontSize: 16, native: true),
      _text(466.6, 381.6, anio, fontSize: 16, native: true),
      _text(
        450.6,
        627.6,
        d['urbanizacion'] ?? '',
        fontSize: 18,
        width: 900,
        center: true,
        native: true,
      ),
      _text(220.6, 830.6, d['proyecto'] ?? '', native: true),
      _text(522.6, 830.6, d['uv'] ?? '', native: true),
      _text(830.6, 830.6, d['mz'] ?? '', native: true),
      _text(1130.6, 830.6, d['lt'] ?? '', native: true),
      _text(1460.6, 830.6, d['cat'] ?? '', native: true),
      _text(188.6, 1095.6, d['plazo_contado'] ?? '', native: true),
      _text(502.6, 1095.6, d['mt2'] ?? '', native: true),
      _text(1130.6, 1095.6, d['cantidad_plazo'] ?? '', native: true),
      _text(160.6, 1245.6, nombreCompleto, native: true),
      _text(1317.6, 1245.6, d['documento'] ?? '', native: true),
      _text(188.6, 1286.6, d['extension'] ?? '', native: true),
      _text(300.6, 2120.6, nombreCompleto, native: true),
    ];
  }

  List<_Overlay> _form4Fields(Map<String, String> d, Uint8List check) {
    final nombreCompleto = _fullName(d);

    return <_Overlay>[
      _form4Text(588, 432, d['paterno'] ?? '', width: 1124),
      _form4Text(1717, 428, d['materno'] ?? '', width: 1124),
      _form4Text(586, 576, d['nombres'] ?? '', width: 1124),
      _form4Text(1596, 573, d['casada'] ?? '', width: 1124),
      _form4Text(2166, 573, d['prefijo'] ?? '', width: 375),
      _form4Text(700, 819, _dateValue(d['dia']), width: 375),
      _form4Text(928, 819, _dateValue(d['mes']), width: 375),
      _form4Text(1161, 823, _dateValue(d['anio']), width: 375),
      _form4Text(1889, 890, d['documento'] ?? '', width: 1062),
      _form4Text(2262, 887, d['extension'] ?? '', width: 312),
      _form4Text(1030, 1051, d['profesion'] ?? '', width: 1124),
      _form4Text(418, 1279, d['costo_vivienda'] ?? '', width: 437),
      _form4Text(1191, 1278, d['propietario'] ?? '', width: 1124),
      _form4Text(2068, 1279, d['telf_propietario'] ?? '', width: 687),
      _form4Text(513, 1508, d['ciudad'] ?? '', width: 1124),
      _form4Text(1641, 1506, d['barrio'] ?? '', width: 1124),
      _form4Text(729, 1641, d['avenida'] ?? '', width: 1124),
      _form4Text(1680, 1639, d['calle'] ?? '', width: 1124),
      _form4Text(2186, 1643, d['numero'] ?? '', width: 375),
      _form4Text(378, 1821, d['telf_fijo'] ?? '', width: 375),
      _form4Text(876, 1824, d['telf_movil'] ?? '', width: 750),
      _form4Text(1678, 1823, d['correo'] ?? '', width: 1500),
      _form4Text(565, 1956, d['referencia1'] ?? '', width: 1124),
      _form4Text(1470, 1963, d['relacion1'] ?? '', width: 1124),
      _form4Text(2108, 1959, d['telf_ref1'] ?? '', width: 687),
      _form4Text(568, 2084, d['referencia2'] ?? '', width: 1124),
      _form4Text(1471, 2089, d['relacion2'] ?? '', width: 1124),
      _form4Text(2115, 2089, d['telf_ref2'] ?? '', width: 687),
      _form4Text(600, 2271, d['empresa'] ?? '', width: 1124),
      _form4Text(1713, 2271, d['direccion'] ?? '', width: 1437),
      _form4Text(601, 2409, d['rubro'] ?? '', width: 1124),
      _form4Text(1630, 2406, d['ingresos'] ?? '', width: 750),
      _form4Text(391, 2546, d['fijo_oficina'] ?? '', width: 375),
      _form4Text(866, 2546, d['movil_oficina'] ?? '', width: 750),
      _form4Text(1300, 2720, d['cargo_publico_detalle'] ?? '', width: 1124),
      _form4Text(
        1300,
        2850,
        d['familiar_cargo_publico_detalle'] ?? '',
        width: 1124,
      ),
      _form4Text(1300, 3010, d['tercero_nombre'] ?? '', width: 1124),
      _form4Text(620, 3100, d['obs1'] ?? '', width: 1437, center: false),
      _form4Text(620, 3150, d['obs2'] ?? '', width: 1437, center: false),
      _form4Text(823, 3588, nombreCompleto, width: 1124),
      _form4Text(
        1941,
        3588,
        _join([d['user_nombres'], d['user_apellidos']]),
        width: 937,
      ),
      ..._form4Options(d, check),
    ];
  }

  static const Map<int, List<double>> _form4MarkPos = {
    1: [1121, 306, 15],
    2: [1331, 303, 15],
    3: [1635, 303, 15],
    9: [632, 709, 55],
    10: [1015, 711, 55],
    11: [466, 768, 55],
    12: [919, 765, 0],
    16: [448, 889, 55],
    17: [680, 888, 55],
    18: [919, 891, 55],
    19: [1209, 889, 55],
    22: [320, 951, 55],
    23: [576, 952, 55],
    24: [560, 1007, 55],
    25: [782, 1005, 55],
    26: [1084, 1003, 55],
    27: [1433, 1002, 55],
    28: [1811, 1002, 55],
    29: [2108, 1004, 55],
    31: [529, 1176, 55],
    32: [679, 1172, 55],
    33: [827, 1174, 55],
    34: [1003, 1175, 55],
    35: [1194, 1175, 55],
    36: [1529, 1177, 55],
    37: [1698, 1174, 55],
    38: [1882, 1172, 55],
    39: [2120, 1171, 55],
    40: [658, 1220, 55],
    44: [271, 1407, 55],
    45: [792, 1388, 0],
    46: [1315, 1400, 65],
    47: [1394, 1404, 65],
    48: [1476, 1404, 65],
    49: [1560, 1404, 65],
    50: [1642, 1405, 65],
    51: [1728, 1404, 65],
    52: [1810, 1403, 65],
    53: [1893, 1405, 65],
    54: [1972, 1401, 65],
    77: [220, 2728, 70],
    78: [325, 2729, 70],
    80: [220, 2858, 70],
    83: [220, 3016, 70],
    81: [327, 2858, 70],
    84: [328, 3016, 70],
    90: [548, 1220, 65],
  };

  List<_Overlay> _form4Options(Map<String, String> d, Uint8List check) {
    final out = <_Overlay>[];

    void ring(int no) {
      final pos = _form4MarkPos[no];
      if (pos == null || pos[2] == 0) return;
      out.add(_form4Ring(pos[0], pos[1], pos[2]));
    }

    void mark(String field, String value, int no) {
      if ((d[field] ?? '').trim() == value) ring(no);
    }

    mark('tipo_participacion', 'Titular', 1);
    mark('tipo_participacion', 'Apoderado', 2);
    mark('tipo_participacion', 'Comprador por cuenta de tercero', 3);

    mark('tipo_documento', 'Carnet de Identidad', 9);
    mark('tipo_documento', 'Pasaporte', 10);

    mark('estado_civil', 'Casado(a)', 16);
    mark('estado_civil', 'Soltero(a)', 17);
    mark('estado_civil', 'Divorciado(a)', 18);
    mark('estado_civil', 'Viudo(a)', 19);

    mark('sexo', 'Masculino', 22);
    mark('sexo', 'Femenino', 23);

    mark('nivel_estudio', 'Primaria', 24);
    mark('nivel_estudio', 'Secundaria', 25);
    mark('nivel_estudio', 'Tecnico Medio', 26);
    mark('nivel_estudio', 'Tecnico Superior', 27);
    mark('nivel_estudio', 'Licenciatura', 28);
    mark('nivel_estudio', 'Ninguno', 29);

    mark('tipo_vivienda', 'Dpto', 31);
    mark('tipo_vivienda', 'Casa', 32);
    mark('tipo_vivienda', 'Cuarto', 33);
    mark('tipo_vivienda', 'Terreno', 34);
    mark('tipo_vivienda', 'Otro', 35);

    mark('tenencia', 'Propia', 36);
    mark('tenencia', 'Alquiler', 37);
    mark('tenencia', 'Anticretico', 38);
    mark('tenencia', 'Otro', 39);

    mark('moneda_vivienda', 'Bs', 90);
    mark('moneda_vivienda', 'USD', 40);

    mark('dpto', 'Santa Cruz', 46);
    mark('dpto', 'La Paz', 47);
    mark('dpto', 'Cochabamba', 48);
    mark('dpto', 'Beni', 49);
    mark('dpto', 'Pando', 50);
    mark('dpto', 'Oruro', 51);
    mark('dpto', 'Potosi', 52);
    mark('dpto', 'Tarija', 53);
    mark('dpto', 'Chuquisaca', 54);

    mark('cargo_publico', 'SI', 77);
    mark('cargo_publico', 'NO', 78);
    mark('familiar_cargo_publico', 'SI', 80);
    mark('familiar_cargo_publico', 'NO', 81);
    mark('compra_tercero', 'SI', 83);
    mark('compra_tercero', 'NO', 84);

    final nacionalidad = (d['nacionalidad'] ?? '').trim();
    final nacionalidadUp = nacionalidad.toUpperCase();
    if (nacionalidadUp == 'BOLIVIANO' || nacionalidadUp == 'BOLIVIANA') {
      ring(11);
    } else if (nacionalidad.isNotEmpty) {
      out.add(_form4Text(919, 765, nacionalidad, width: 1124));
    }

    final pais = (d['pais'] ?? '').trim();
    if (pais.toUpperCase() == 'BOLIVIA') {
      ring(44);
    } else if (pais.isNotEmpty) {
      out.add(_form4Text(792, 1388, pais, width: 1124));
    }

    final monedaIngresos = (d['moneda_ingresos'] ?? '').trim();
    if (monedaIngresos == 'Bs') {
      out.add(_check(2124.5, 2403.5, check, size: _form4CheckSize));
    } else if (monedaIngresos == 'USD') {
      out.add(_check(2289.5, 2407.5, check, size: _form4CheckSize));
    }

    return out;
  }

  _Overlay _form4Ring(double x, double y, double size) {
    return _Overlay.ring(x, y, size);
  }

  _Overlay _form4Text(
    double x,
    double y,
    String text, {
    required double width,
    bool center = true,
  }) {
    final maxWidth = 2 * (x < _form4Width - x ? x : _form4Width - x);
    final clamped = width > maxWidth ? maxWidth : width;
    return _text(
      x,
      y,
      text,
      fontSize: _form4FontSize,
      width: clamped,
      center: center,
      native: true,
    );
  }

  List<_Overlay> _reservaFields(Map<String, String> d) {
    final nombreCompleto = _fullName(d);
    final documento = (d['documento'] ?? '').trim();
    final extension = (d['extension'] ?? '').trim();
    final dpto = (d['dpto'] ?? '').trim() == '--'
        ? ''
        : (d['dpto'] ?? '').trim();
    final dia = _dateValue(d['dia']);
    final mes = _monthName(d['mes']);
    final anio = _dateValue(d['anio']);
    return [
      _text(848.6, 644.6, nombreCompleto, native: true),
      _text(867.6, 716.6, documento, width: 500, center: true, native: true),
      _text(1435.6, 716.6, extension, width: 450, center: true, native: true),
      _text(
        363.6,
        893.6,
        d['proyecto'] ?? '',
        width: 500,
        center: true,
        native: true,
      ),
      _text(
        748.6,
        893.6,
        d['uv'] ?? '',
        width: 550,
        center: true,
        native: true,
      ),
      _text(
        1048.6,
        893.6,
        d['mz'] ?? '',
        width: 550,
        center: true,
        native: true,
      ),
      _text(
        1352.6,
        893.6,
        d['lt'] ?? '',
        width: 550,
        center: true,
        native: true,
      ),
      _text(
        1608.6,
        893.6,
        d['cat'] ?? '',
        width: 550,
        center: true,
        native: true,
      ),
      _text(
        1893.6,
        893.6,
        d['mt2'] ?? '',
        width: 420,
        center: true,
        native: true,
      ),
      _text(230.6, 1944.6, nombreCompleto, native: true),
      _text(1592.6, 2011.6, dpto, native: true),
      _text(860.6, 2014.6, documento, native: true),
      _text(1680.6, 2130.6, mes, native: true),
      _text(328.6, 2130.6, dpto, native: true),
      _text(1070.6, 2130.6, dia, native: true),
      _text(450.6, 2189.6, anio, native: true),
      _text(1098.6, 2828.6, _join([documento, extension]), native: true),
    ];
  }

  String _monthName(String? value) {
    const months = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final n = int.tryParse((value ?? '').trim());
    if (n == null || n < 1 || n > 12) return '';
    return months[n];
  }

  List<_Overlay> _cosolFields(Map<String, String> d) {
    final nombreCompleto = _join([
      d['nombres'],
      d['paterno'],
      d['materno'],
      d['prefijo'],
      d['casada'],
    ]);
    final ingresos = _join([
      (d['ingresos'] ?? '').trim(),
      (d['moneda_ingresos'] ?? '').trim(),
    ]);
    return [
      _Overlay(
        683,
        440,
        d['tipo_relacion'] ?? '',
        center: true,
        native: true,
        width: 450,
      ),
      _Overlay(
        424,
        573,
        d['paterno'] ?? '',
        center: true,
        native: true,
        width: 450,
      ),
      _Overlay(
        1221,
        573,
        d['materno'] ?? '',
        center: true,
        native: true,
        width: 450,
      ),
      _Overlay(
        425,
        691,
        d['nombres'] ?? '',
        center: true,
        native: true,
        width: 450,
      ),
      _Overlay(
        1221,
        691,
        d['casada'] ?? '',
        center: true,
        native: true,
        width: 450,
      ),
      _Overlay(
        536,
        809,
        d['tipo_identificacion'] ?? '',
        center: true,
        native: true,
        width: 500,
      ),
      _Overlay(
        1109,
        818,
        d['documento'] ?? '',
        center: true,
        native: true,
        width: 400,
      ),
      _Overlay(
        1456,
        818,
        d['extension'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        534,
        846,
        d['fecha_nacimiento'] ?? '',
        center: true,
        native: true,
        width: 300,
      ),
      _Overlay(
        533,
        881,
        d['sexo'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        532,
        914,
        d['estado_civil'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        532,
        957,
        d['nivel_estudio'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        533,
        993,
        d['profesion'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        532,
        1029,
        d['nacionalidad'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        532,
        1111,
        d['pais'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        532,
        1149,
        d['dpto'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        206,
        1294,
        d['telf_fijo'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        580,
        1294,
        d['telf_movil'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        1171,
        1293,
        d['lugar_trabajo'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        203,
        1408,
        d['telf_fijo_oficina'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        577,
        1408,
        d['telf_movil_oficina'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(
        1169,
        1410,
        d['direccion'] ?? '',
        center: true,
        native: true,
        width: 450,
      ),
      _Overlay(
        397,
        1515,
        d['correo'] ?? '',
        center: true,
        native: true,
        width: 450,
      ),
      _Overlay(
        1039,
        1515,
        d['rubro'] ?? '',
        center: true,
        native: true,
        width: 350,
      ),
      _Overlay(1455, 1515, ingresos, center: true, native: true, width: 350),
      _Overlay(354, 2152, nombreCompleto, native: true),
      _Overlay(
        1233,
        2152,
        _join([d['user_nombres'], d['user_apellidos']]),
        native: true,
      ),
    ];
  }

  List<_Overlay> _mapaFields(Map<String, String> d) {
    final direccion = _join([
      _labeled('Avenida', d['avenida']),
      _labeled('Calle', d['calle']),
      _labeled('Barrio', d['barrio']),
      _labeled('Nro Casa', d['numero']),
    ]);
    final referencias = [
      _referencia(d['relacion1'], d['referencia1'], d['telf_ref1']),
      _referencia(d['relacion2'], d['referencia2'], d['telf_ref2']),
    ].where((e) => e.isNotEmpty).join(' ; ');
    return [
      _text(381.1, 319.1, d['uv'] ?? '', native: true),
      _text(790.1, 319.1, d['mz'] ?? '', native: true),
      _text(1184.1, 319.1, d['lt'] ?? '', native: true),
      _text(1501.1, 319.1, d['cat'] ?? '', native: true),
      _text(506.1, 398.1, _fullName(d), native: true),
      _text(
        505.1,
        444.1,
        _join([d['documento'], d['extension']]),
        native: true,
      ),
      _text(1105.1, 444.1, (d['telf_movil'] ?? '').trim(), native: true),
      _text(506.1, 497.1, direccion, native: true),
      _text(506.1, 547.1, referencias, native: true),
      _text(507.1, 601.1, (d['zona'] ?? '').trim(), native: true),
      _text(134.1, 2494.1, d['obs1'] ?? '', native: true),
      _text(134.1, 2532.1, d['obs2'] ?? '', native: true),
      if ((d['ubicacion'] ?? '').trim().isNotEmpty)
        _Overlay.qr(
          1414.0,
          2290.0,
          191.0,
          161.0,
          (d['ubicacion'] ?? '').trim(),
          text: '',
        ),
    ];
  }

  String _labeled(String label, String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? '' : '$label: $trimmed';
  }

  String _referencia(String? relacion, String? nombre, String? telf) {
    final rel = (relacion ?? '').trim();
    final name = (nombre ?? '').trim();
    final phone = (telf ?? '').trim();
    if (rel.isEmpty && name.isEmpty && phone.isEmpty) return '';
    final head = [
      if (rel.isNotEmpty && name.isNotEmpty) '$rel: $name',
      if (rel.isEmpty && name.isNotEmpty) name,
    ].join();
    return _join([
      if (head.isNotEmpty) head,
      if (phone.isNotEmpty) 'telf: $phone',
    ]);
  }

  _Overlay _mapaBoxOverlay(Uint8List bytes) {
    return _Overlay.box(
      _mapaBoxLeft,
      _mapaBoxTop,
      _mapaBoxWidth,
      _mapaBoxHeight,
      bytes,
      text: '',
    );
  }

  Future<Uint8List> _downscaleToMax(Uint8List bytes, double maxDim) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final w = src.width.toDouble();
    final h = src.height.toDouble();
    if (w <= maxDim && h <= maxDim) {
      src.dispose();
      return bytes;
    }
    final scale = maxDim / (w > h ? w : h);
    final tw = (w * scale).round();
    final th = (h * scale).round();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      src,
      ui.Rect.fromLTWH(0, 0, w, h),
      ui.Rect.fromLTWH(0, 0, tw.toDouble(), th.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final img = await picture.toImage(tw, th);
    final result = await img.toByteData(format: ui.ImageByteFormat.png);
    src.dispose();
    img.dispose();
    return result!.buffer.asUint8List();
  }

  _Overlay _text(
    double left,
    double top,
    String text, {
    double fontSize = 12,
    double? width,
    bool center = false,
    bool native = false,
  }) {
    return _Overlay(
      left,
      top,
      text,
      fontSize: fontSize,
      width: width,
      center: center,
      native: native,
    );
  }

  _Overlay _check(
    double centerX,
    double centerY,
    Uint8List image, {
    double size = _checkSize,
  }) {
    return _Overlay(
      centerX,
      centerY,
      '',
      fontSize: 12,
      image: image,
      imageSize: size,
    );
  }

  String _dateValue(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '';
    return trimmed.padLeft(2, '0');
  }

  String _fullName(Map<String, String> d) {
    final prefijo = (d['prefijo'] ?? '').trim();
    final casada = (d['casada'] ?? '').trim();
    return _join([
      d['nombres'],
      d['paterno'],
      d['materno'],
      if (prefijo.isNotEmpty && casada.isNotEmpty) '$prefijo $casada',
    ]);
  }

  String _join(List<String?> parts) {
    return parts
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(' ');
  }

  Map<String, String> _parse(String raw) {
    final map = <String, String>{};
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('[') ||
          trimmed.startsWith('=')) {
        continue;
      }
      final index = trimmed.indexOf('=');
      if (index == -1) continue;
      final key = trimmed.substring(0, index).trim();
      final value = trimmed.substring(index + 1).trim();
      if (key.isNotEmpty) {
        map[key] = value;
      }
    }
    return map;
  }
}

class _Overlay {
  _Overlay(
    this.left,
    this.top,
    this.text, {
    this.fontSize = 12,
    this.width,
    this.center = false,
    this.native = false,
    this.image,
    this.imageSize,
  }) : ringSize = null,
       ringStroke = null;

  _Overlay.ring(this.left, this.top, double size, {double stroke = 2.0})
    : ringSize = size,
      ringStroke = stroke,
      text = '',
      fontSize = 12,
      width = null,
      center = true,
      native = true,
      image = null,
      imageSize = null,
      imageBox = null,
      qr = null;

  _Overlay.box(
    this.left,
    this.top,
    this.width,
    this.height,
    this.imageBox, {
    required this.text,
  }) : fontSize = 12,
       center = false,
       native = true,
       image = null,
       imageSize = null,
       ringSize = null,
       ringStroke = null,
       qr = null;

  _Overlay.qr(
    this.left,
    this.top,
    this.width,
    this.height,
    this.qr, {
    required this.text,
  }) : fontSize = 12,
       center = false,
       native = true,
       image = null,
       imageSize = null,
       ringSize = null,
       ringStroke = null,
       imageBox = null;

  final double left;
  final double top;
  final String text;
  final double fontSize;
  final double? width;
  double? height;
  final bool center;
  final bool native;
  final Uint8List? image;
  final double? imageSize;
  final double? ringSize;
  final double? ringStroke;
  Uint8List? imageBox;
  String? qr;
}
