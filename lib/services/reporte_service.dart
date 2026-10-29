import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class ReporteProspecto {
  const ReporteProspecto({
    required this.id,
    required this.createdAt,
    required this.prospecto,
    required this.telefono,
    required this.origenProspecto,
    required this.informacion,
    required this.vigencia,
    required this.nombreCompletoRegistrador,
    required this.usuarioRegistrador,
  });

  final int id;
  final DateTime? createdAt;
  final String prospecto;
  final String telefono;
  final String origenProspecto;
  final String informacion;
  final String vigencia;
  final String nombreCompletoRegistrador;
  final String usuarioRegistrador;
}

class ReporteCita {
  const ReporteCita({
    required this.id,
    required this.createdAt,
    required this.contrato,
    required this.cliente,
    required this.fechaCita,
    required this.horaCita,
    required this.informacion,
    required this.estado,
    required this.nombreCompletoRegistrador,
    required this.usuarioRegistrador,
  });

  final int id;
  final DateTime? createdAt;
  final String contrato;
  final String cliente;
  final String fechaCita;
  final String horaCita;
  final String informacion;
  final String estado;
  final String nombreCompletoRegistrador;
  final String usuarioRegistrador;
}

class ReporteService {
  ReporteService._();

  static final ReporteService instance = ReporteService._();

  static const int _tamanoPagina = 1000;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _ensureInitialized() => SupabaseConfig.ensureInitialized();

  Future<List<ReporteProspecto>> fetchProspectos(
    DateTime fechaInicial,
    DateTime fechaFinal,
  ) async {
    await _ensureInitialized();
    final rango = _rangoUtc(fechaInicial, fechaFinal);
    final resultados = <ReporteProspecto>[];
    var offset = 0;

    while (true) {
      final respuesta = await _client
          .from('prospectos')
          .select(
            'id, created_at, prospecto, telefono, origen_prospecto, '
            'informacion, vigencia, '
            'registrador:usuario(nombres, apellidos, usuario)',
          )
          .gte('created_at', rango.desde)
          .lt('created_at', rango.hasta)
          .order('created_at', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + _tamanoPagina - 1);

      final filas = respuesta as List;
      resultados.addAll(
        filas.map((fila) => _mapProspecto(fila as Map<String, dynamic>)),
      );

      if (filas.length < _tamanoPagina) break;
      offset += _tamanoPagina;
    }

    return resultados;
  }

  Future<List<ReporteCita>> fetchCitas(
    DateTime fechaInicial,
    DateTime fechaFinal,
  ) async {
    await _ensureInitialized();
    final rango = _rangoUtc(fechaInicial, fechaFinal);
    final resultados = <ReporteCita>[];
    var offset = 0;

    while (true) {
      final respuesta = await _client
          .from('cita')
          .select(
            'id, created_at, contrato, cliente, fecha_cita, hora_cita, '
            'informacion, estado, '
            'registrador:usuario(nombres, apellidos, usuario)',
          )
          .gte('created_at', rango.desde)
          .lt('created_at', rango.hasta)
          .order('created_at', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + _tamanoPagina - 1);

      final filas = respuesta as List;
      resultados.addAll(
        filas.map((fila) => _mapCita(fila as Map<String, dynamic>)),
      );

      if (filas.length < _tamanoPagina) break;
      offset += _tamanoPagina;
    }

    return resultados;
  }

  ({String desde, String hasta}) _rangoUtc(
    DateTime fechaInicial,
    DateTime fechaFinal,
  ) {
    final inicio = DateTime(
      fechaInicial.year,
      fechaInicial.month,
      fechaInicial.day,
    );
    final finExclusivo = DateTime(
      fechaFinal.year,
      fechaFinal.month,
      fechaFinal.day,
    ).add(const Duration(days: 1));

    return (
      desde: inicio.toUtc().toIso8601String(),
      hasta: finExclusivo.toUtc().toIso8601String(),
    );
  }

  ReporteProspecto _mapProspecto(Map<String, dynamic> fila) {
    final registrador = _registrador(fila['registrador']);
    return ReporteProspecto(
      id: fila['id'] as int,
      createdAt: _fechaHoraLocal(fila['created_at']),
      prospecto: _texto(fila['prospecto']),
      telefono: _texto(fila['telefono']),
      origenProspecto: _texto(fila['origen_prospecto']),
      informacion: _texto(fila['informacion']),
      vigencia: _texto(fila['vigencia']),
      nombreCompletoRegistrador: registrador.nombreCompleto,
      usuarioRegistrador: registrador.usuario,
    );
  }

  ReporteCita _mapCita(Map<String, dynamic> fila) {
    final registrador = _registrador(fila['registrador']);
    return ReporteCita(
      id: fila['id'] as int,
      createdAt: _fechaHoraLocal(fila['created_at']),
      contrato: _texto(fila['contrato']),
      cliente: _texto(fila['cliente']),
      fechaCita: _texto(fila['fecha_cita']),
      horaCita: _texto(fila['hora_cita']),
      informacion: _texto(fila['informacion']),
      estado: _texto(fila['estado']),
      nombreCompletoRegistrador: registrador.nombreCompleto,
      usuarioRegistrador: registrador.usuario,
    );
  }

  String _texto(dynamic valor) => valor == null ? '' : '$valor';

  DateTime? _fechaHoraLocal(dynamic valor) {
    final texto = _texto(valor);
    if (texto.isEmpty) return null;
    return DateTime.tryParse(texto)?.toLocal();
  }

  _DatosRegistrador _registrador(dynamic valor) {
    if (valor is! Map) return const _DatosRegistrador('', '');
    final nombres = _texto(valor['nombres']).trim();
    final apellidos = _texto(valor['apellidos']).trim();
    final nombreCompleto = [
      nombres,
      apellidos,
    ].where((parte) => parte.isNotEmpty).join(' ');
    return _DatosRegistrador(nombreCompleto, _texto(valor['usuario']).trim());
  }
}

class _DatosRegistrador {
  const _DatosRegistrador(this.nombreCompleto, this.usuario);

  final String nombreCompleto;
  final String usuario;
}
