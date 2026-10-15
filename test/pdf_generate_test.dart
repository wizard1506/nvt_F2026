import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:novitierra_f/services/form_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generatePdf builds a valid 3-page PDF', () async {
    final service = FormGeneratorService();
    final data = await service.loadSampleData();
    expect(data, isNotEmpty);

    final bytes = await service.generatePdf(data);
    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(50_000));

    final header = String.fromCharCodes(bytes.take(8));
    expect(
      header.startsWith('%PDF-1.'),
      isTrue,
      reason: 'Debe ser un PDF v\u00e1lido',
    );

    final pageCountMatches = RegExp(r'/Type\s*/Page[^s]')
        .allMatches(String.fromCharCodes(bytes));
    expect(
      pageCountMatches.length,
      greaterThanOrEqualTo(3),
      reason: 'Debe contener las 3 p\u00e1ginas del formulario',
    );
  });

  test('generatePdf builds 4 pages with generar_reserva=SI', () async {
    final service = FormGeneratorService();
    final data = await service.loadSampleData();
    data['generar_reserva'] = 'SI';

    final bytes = await service.generatePdf(data);
    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(50_000));

    final pageCountMatches = RegExp(r'/Type\s*/Page[^s]')
        .allMatches(String.fromCharCodes(bytes));
    expect(
      pageCountMatches.length,
      greaterThanOrEqualTo(4),
      reason: 'Debe contener las 4 p\u00e1ginas del formulario',
    );
  });

  test('generatePdf adds the Mapa page when an image is attached', () async {
    final service = FormGeneratorService();
    final data = await service.loadSampleData();
    data
      ..['uv'] = '358'
      ..['zona'] = 'Equipetrol Norte'
      ..['avenida'] = 'Los Cusis'
      ..['relacion1'] = 'hermano'
      ..['referencia1'] = 'Juan Perez'
      ..['telf_ref1'] = '23232'
      ..['ubicacion'] = 'https://ejemplo.com/registro/6843210';
    const transparentPng =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    final mapaImagen = base64Decode(transparentPng);

    final bytes = await service.generatePdf(data, mapaImagen: mapaImagen);
    expect(bytes, isNotNull);

    final pageCountMatches = RegExp(r'/Type\s*/Page[^s]')
        .allMatches(String.fromCharCodes(bytes));
    expect(
      pageCountMatches.length,
      greaterThanOrEqualTo(4),
      reason: 'Debe agregar la p\u00e1gina del Mapa',
    );
  });

  test('generateCosolPdf builds a valid PDF', () async {
    final service = FormGeneratorService();
    final data = <String, String>{
      'tipo_relacion': 'Cónyuge',
      'paterno': 'Perez',
      'materno': 'Lopez',
      'nombres': 'Maria Fernanda',
      'casada': 'Gutierrez',
      'prefijo': 'VDA DE',
      'tipo_identificacion': 'Carnet de Identidad',
      'documento': '6843210',
      'extension': 'SC',
      'fecha_nacimiento': '15/03/1985',
      'sexo': 'Femenino',
      'estado_civil': 'Casado(a)',
      'nivel_estudio': 'Licenciatura',
      'profesion': 'Ingeniera Civil',
      'nacionalidad': 'Boliviana',
      'pais': 'Bolivia',
      'dpto': 'Santa Cruz',
      'telf_fijo': '3444321',
      'telf_movil': '71234567',
      'telf_fijo_oficina': '3330001',
      'telf_movil_oficina': '70011223',
      'lugar_trabajo': 'Constructora Andina',
      'direccion': 'Av. Monseñor Rivero Nro 400',
      'correo': 'maria@gutierrez.com',
      'rubro': 'Construcción',
      'ingresos': '15000',
      'moneda_ingresos': 'Bs.',
      'asesor': 'Lic. Ana Roca',
    };

    final bytes = await service.generateCosolPdf(data);
    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(50_000));

    final header = String.fromCharCodes(bytes.take(8));
    expect(
      header.startsWith('%PDF-1.'),
      isTrue,
      reason: 'Debe ser un PDF v\u00e1lido',
    );

    final pageCountMatches = RegExp(r'/Type\s*/Page[^s]')
        .allMatches(String.fromCharCodes(bytes));
    expect(
      pageCountMatches.length,
      greaterThanOrEqualTo(1),
      reason: 'Debe contener al menos la p\u00e1gina del co-solicitante',
    );
  });
}
