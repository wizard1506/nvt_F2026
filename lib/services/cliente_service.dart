import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/fechas.dart';
import 'sesion.dart';

class Urbanizacion {
  const Urbanizacion({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory Urbanizacion.fromJson(Map<String, dynamic> json) => Urbanizacion(
    id: json['id'] as int,
    nombre: (json['urbanizacion'] as String?) ?? '',
  );
}

class ClienteResumen {
  const ClienteResumen({
    required this.id,
    required this.nombreCompleto,
    required this.urbanizacion,
    required this.uv,
    required this.mz,
    required this.lt,
    required this.cat,
    required this.mt2,
    required this.fecha,
  });

  final int id;
  final String nombreCompleto;
  final String urbanizacion;
  final String uv;
  final String mz;
  final String lt;
  final String cat;
  final String mt2;
  final String fecha;
}

class PaginaClientes {
  const PaginaClientes({required this.items, required this.total});

  final List<ClienteResumen> items;
  final int total;
}

class UsuarioResumen {
  const UsuarioResumen({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory UsuarioResumen.fromJson(Map<String, dynamic> json) {
    final nombres = '${json['nombres'] ?? ''}';
    final apellidos = '${json['apellidos'] ?? ''}';
    final nombre = [
      nombres,
      apellidos,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
    return UsuarioResumen(id: json['id'] as int, nombre: nombre);
  }
}

class CitaResumen {
  const CitaResumen({
    required this.id,
    required this.contrato,
    required this.cliente,
    required this.fecha,
    required this.hora,
    required this.informacion,
    required this.estado,
    required this.usuarioId,
    required this.asignadoA,
  });

  final int id;
  final String contrato;
  final String cliente;
  final String fecha;
  final String hora;
  final String informacion;
  final String estado;
  final int? usuarioId;
  final String asignadoA;
}

class PaginaCitas {
  const PaginaCitas({required this.items, required this.total});

  final List<CitaResumen> items;
  final int total;
}

class ProspectoResumen {
  const ProspectoResumen({
    required this.id,
    required this.prospecto,
    required this.telefono,
    required this.origenProspecto,
    required this.informacion,
    required this.vigencia,
    required this.creadoPor,
    required this.usuarioId,
    required this.createdAt,
  });

  final int id;
  final String prospecto;
  final String telefono;
  final String origenProspecto;
  final String informacion;
  final String vigencia;
  final String creadoPor;
  final int? usuarioId;
  final String createdAt;
}

class PaginaProspectos {
  const PaginaProspectos({required this.items, required this.total});

  final List<ProspectoResumen> items;
  final int total;
}

class CosolicitanteResumen {
  const CosolicitanteResumen({
    required this.id,
    required this.nombreCompleto,
    required this.documento,
    required this.telefonoMovil,
    required this.creadoPor,
    required this.usuarioId,
    required this.createdAt,
  });

  final int id;
  final String nombreCompleto;
  final String documento;
  final String telefonoMovil;
  final String creadoPor;
  final int? usuarioId;
  final String createdAt;
}

class PaginaCosolicitantes {
  const PaginaCosolicitantes({required this.items, required this.total});

  final List<CosolicitanteResumen> items;
  final int total;
}

class ClienteService {
  ClienteService._();
  static final ClienteService instance = ClienteService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _ensureInitialized() => SupabaseConfig.ensureInitialized();

  Future<List<Urbanizacion>> fetchUrbanizaciones() async {
    await _ensureInitialized();
    final response = await _client
        .from('urbanizacion')
        .select('id, urbanizacion')
        .order('urbanizacion');
    return (response as List)
        .map((row) => Urbanizacion.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<int> insertarUrbanizacion(String nombre) async {
    await _ensureInitialized();
    final response = await _client
        .from('urbanizacion')
        .insert({'urbanizacion': nombre.trim()})
        .select('id')
        .single();
    return response['id'] as int;
  }

  Future<void> insertarCliente(Map<String, dynamic> payload) async {
    await _ensureInitialized();
    await _client.from('clientes').insert(payload);
  }

  Future<Map<String, dynamic>?> fetchClientePorId(int id) async {
    await _ensureInitialized();
    final response = await _client
        .from('clientes')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  Future<void> actualizarCliente(int id, Map<String, dynamic> payload) async {
    await _ensureInitialized();
    await _client.from('clientes').update(payload).eq('id', id);
  }

  Future<void> insertarCosolicitante(Map<String, dynamic> payload) async {
    await _ensureInitialized();
    await _client.from('cosolicitante').insert(payload);
  }

  Future<void> actualizarCosolicitante(
    int id,
    Map<String, dynamic> payload,
  ) async {
    await _ensureInitialized();
    await _client.from('cosolicitante').update(payload).eq('id', id);
  }

  Future<Map<String, dynamic>?> fetchCosolicitantePorId(int id) async {
    await _ensureInitialized();
    final response = await _client
        .from('cosolicitante')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  Future<PaginaCosolicitantes> fetchCosolicitantes({
    required int pagina,
    required int porPagina,
    String busqueda = '',
  }) async {
    await _ensureInitialized();
    final termino = busqueda.trim();
    var query = _client
        .from('cosolicitante')
        .select(
          'id, nombres, paterno, materno, casada, prefijo, documento, '
          'extension, telf_movil, usuario, created_at, '
          'usuario(id, nombres, apellidos)',
        );

    final rol = Sesion.instance.rol;
    if (rol != 1 && rol != 2) {
      final userId = Sesion.instance.id;
      if (userId != null) {
        query = query.eq('usuario', userId);
      }
    }

    if (termino.isNotEmpty) {
      final condiciones = <String>[
        'nombres.ilike.%$termino%',
        'paterno.ilike.%$termino%',
        'materno.ilike.%$termino%',
        'casada.ilike.%$termino%',
        'documento.ilike.%$termino%',
      ];
      query = query.or(condiciones.join(','));
    }

    final respuesta = await query
        .order('id', ascending: false)
        .range(pagina * porPagina, pagina * porPagina + porPagina - 1)
        .count(CountOption.exact);

    final filas = respuesta.data as List;
    return PaginaCosolicitantes(
      items: filas
          .map((row) => _mapCosolicitante(row as Map<String, dynamic>))
          .toList(),
      total: respuesta.count,
    );
  }

  CosolicitanteResumen _mapCosolicitante(Map<String, dynamic> row) {
    final usuario = row['usuario'];
    String creadoPor = '';
    int? usuarioId;
    if (usuario is Map<String, dynamic>) {
      final nombres = '${usuario['nombres'] ?? ''}';
      final apellidos = '${usuario['apellidos'] ?? ''}';
      creadoPor = [
        nombres,
        apellidos,
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
      usuarioId = usuario['id'] as int?;
    } else if (usuario is int) {
      usuarioId = usuario;
    }

    String limpiar(String? valor) {
      final texto = (valor ?? '').trim();
      if (texto.isEmpty || texto == '--' || texto == 'NINGUNO') return '';
      return texto;
    }

    final nombre = [
      limpiar(row['nombres'] as String?),
      limpiar(row['paterno'] as String?),
      limpiar(row['materno'] as String?),
    ].where((e) => e.isNotEmpty).join(' ');

    final documento = limpiar(row['documento'] as String?);
    final extension = limpiar(row['extension'] as String?);

    return CosolicitanteResumen(
      id: row['id'] as int,
      nombreCompleto: nombre.isEmpty ? '(Sin nombre)' : nombre,
      documento: documento.isEmpty
          ? ''
          : (extension.isEmpty ? documento : '$documento $extension'),
      telefonoMovil: limpiar(row['telf_movil'] as String?),
      creadoPor: creadoPor,
      usuarioId: usuarioId,
      createdAt: '${row['created_at'] ?? ''}',
    );
  }

  Future<List<UsuarioResumen>> fetchUsuariosAsignables() async {
    await _ensureInitialized();
    final response = await _client
        .from('usuario')
        .select('id, nombres, apellidos')
        .inFilter('rol', [5, 6])
        .order('nombres');
    return (response as List)
        .map((row) => UsuarioResumen.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<PaginaCitas> fetchCitas({
    required int pagina,
    required int porPagina,
    String busqueda = '',
  }) async {
    await _ensureInitialized();
    final termino = busqueda.trim();
    final condiciones = <String>[];

    if (termino.isNotEmpty) {
      condiciones.add('contrato.ilike.%$termino%');
      condiciones.add('cliente.ilike.%$termino%');

      final usuarioMatch = await _client
          .from('usuario')
          .select('id')
          .or('nombres.ilike.%$termino%,apellidos.ilike.%$termino%');
      final usuarioIds = [for (final row in usuarioMatch as List) row['id']];
      if (usuarioIds.isNotEmpty) {
        condiciones.add('usuario.in.(${usuarioIds.join(',')})');
      }
    }

    var query = _client
        .from('cita')
        .select(
          'id, contrato, cliente, fecha_cita, hora_cita, informacion, estado, '
          'usuario(id, nombres, apellidos)',
        );

    final rol = Sesion.instance.rol;
    if (rol != 1 && rol != 5) {
      final userId = Sesion.instance.id;
      if (userId != null) {
        query = query.eq('usuario', userId);
      }
    }

    if (condiciones.isNotEmpty) {
      query = query.or(condiciones.join(','));
    }

    final respuesta = await query
        .order('fecha_cita', ascending: false)
        .order('hora_cita', ascending: false)
        .range(pagina * porPagina, pagina * porPagina + porPagina - 1)
        .count(CountOption.exact);

    final filas = respuesta.data as List;
    return PaginaCitas(
      items: filas.map((row) => _mapCita(row as Map<String, dynamic>)).toList(),
      total: respuesta.count,
    );
  }

  Future<Map<String, int>> contarCuposPorHorario(String isoFecha) async {
    await _ensureInitialized();
    final response = await _client
        .from('cita')
        .select('hora_cita')
        .eq('fecha_cita', isoFecha);
    final conteo = <String, int>{};
    for (final row in response as List) {
      final hora = (row as Map<String, dynamic>)['hora_cita'] as String?;
      if (hora == null) continue;
      conteo[hora] = (conteo[hora] ?? 0) + 1;
    }
    return conteo;
  }

  Future<void> insertarCita(Map<String, dynamic> payload) async {
    await _ensureInitialized();
    await _client.from('cita').insert(payload);
  }

  Future<void> actualizarUsuarioCita(int citaId, int usuarioId) async {
    await _ensureInitialized();
    await _client.from('cita').update({'usuario': usuarioId}).eq('id', citaId);
  }

  Future<void> actualizarEstadoCita(int citaId, String estado) async {
    await _ensureInitialized();
    await _client.from('cita').update({'estado': estado}).eq('id', citaId);
  }

  Future<void> actualizarInformacionCita(
    int citaId,
    String? informacion,
  ) async {
    await _ensureInitialized();
    await _client
        .from('cita')
        .update({'informacion': informacion})
        .eq('id', citaId);
  }

  Future<void> actualizarCitaInfoYEstado(
    int citaId,
    String? informacion,
    String estado,
  ) async {
    await _ensureInitialized();
    await _client
        .from('cita')
        .update({'informacion': informacion, 'estado': estado})
        .eq('id', citaId);
  }

  Future<void> eliminarCita(int citaId) async {
    await _ensureInitialized();
    await _client.from('cita').delete().eq('id', citaId);
  }

  Future<Map<String, int>> contarCitasPorDia(
    DateTime desde,
    DateTime hasta,
  ) async {
    await _ensureInitialized();
    final desdeIso = _isoFecha(desde);
    final hastaIso = _isoFecha(hasta);
    const pageSize = 1000;
    var offset = 0;
    final conteo = <String, int>{};
    while (true) {
      final query = _client
          .from('cita')
          .select('fecha_cita')
          .gte('fecha_cita', desdeIso)
          .lte('fecha_cita', hastaIso);
      final response = await query.range(offset, offset + pageSize - 1);
      final filas = response as List;
      for (final row in filas) {
        final fecha = (row as Map<String, dynamic>)['fecha_cita'] as String?;
        if (fecha == null || fecha.isEmpty) continue;
        conteo[fecha] = (conteo[fecha] ?? 0) + 1;
      }
      if (filas.length < pageSize) break;
      offset += pageSize;
    }
    return conteo;
  }

  Future<List<CitaResumen>> fetchCitasDelDia(DateTime fecha) async {
    await _ensureInitialized();
    var query = _client
        .from('cita')
        .select(
          'id, contrato, cliente, fecha_cita, hora_cita, informacion, estado, '
          'usuario(id, nombres, apellidos)',
        )
        .eq('fecha_cita', _isoFecha(fecha));
    final response = await query.order('hora_cita');
    return (response as List)
        .map((row) => _mapCita(row as Map<String, dynamic>))
        .toList();
  }

  String _isoFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  CitaResumen _mapCita(Map<String, dynamic> row) {
    final usuario = row['usuario'];
    int? usuarioId;
    var asignadoA = '';
    if (usuario is Map<String, dynamic>) {
      usuarioId = usuario['id'] as int?;
      asignadoA = [
        '${usuario['nombres'] ?? ''}',
        '${usuario['apellidos'] ?? ''}',
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
    } else if (usuario is int) {
      usuarioId = usuario;
    }
    return CitaResumen(
      id: row['id'] as int,
      contrato: '${row['contrato'] ?? ''}',
      cliente: '${row['cliente'] ?? ''}',
      fecha: dmaDesdeIso(row['fecha_cita'] as String?),
      hora: '${row['hora_cita'] ?? ''}',
      informacion: '${row['informacion'] ?? ''}',
      estado: '${row['estado'] ?? ''}',
      usuarioId: usuarioId,
      asignadoA: asignadoA,
    );
  }

  Future<PaginaClientes> fetchClientes({
    required int usuarioId,
    required int pagina,
    required int porPagina,
    String busqueda = '',
    List<int> urbanizacionIds = const [],
  }) async {
    await _ensureInitialized();
    final builder = _client
        .from('clientes')
        .select(
          'id, paterno, materno, nombres, casada, prefijo, urbanizacion, uv, mz, lt, cat, mt2, fecha_form',
        )
        .eq('usuario', usuarioId);

    final termino = busqueda.trim();
    var query = builder;
    if (termino.isNotEmpty) {
      final condiciones = <String>[
        'or(paterno.ilike.%$termino%,materno.ilike.%$termino%,nombres.ilike.%$termino%)',
      ];
      if (urbanizacionIds.isNotEmpty) {
        condiciones.add('urbanizacion.in.(${urbanizacionIds.join(',')})');
      }
      query = query.or(condiciones.join(','));
    }

    final respuesta = await query
        .order('id', ascending: false)
        .range(pagina * porPagina, pagina * porPagina + porPagina - 1)
        .count(CountOption.exact);

    final filas = respuesta.data as List;
    return PaginaClientes(
      items: filas
          .map((row) => _mapCliente(row as Map<String, dynamic>))
          .toList(),
      total: respuesta.count,
    );
  }

  Future<bool> telefonoTieneVigenciaActiva(String telefono) async {
    await _ensureInitialized();
    final telTrim = telefono.trim();
    if (telTrim.isEmpty) return false;
    final telNum = BigInt.tryParse(telTrim.replaceAll(RegExp(r'\D'), ''));
    if (telNum == null) return false;
    final hoyIso = _isoFecha(DateTime.now());
    final response = await _client
        .from('prospectos')
        .select('id')
        .eq('telefono', telNum.toString())
        .gte('vigencia', hoyIso)
        .limit(1);
    final filas = response as List;
    return filas.isNotEmpty;
  }

  Future<bool> puedeRegistrarTelefono(String telefono) async {
    await _ensureInitialized();
    final telTrim = telefono.trim();
    if (telTrim.isEmpty) return true;
    final telNum = BigInt.tryParse(telTrim.replaceAll(RegExp(r'\D'), ''));
    if (telNum == null) return true;
    final hoyIso = _isoFecha(DateTime.now());
    final response = await _client
        .from('prospectos')
        .select('id')
        .eq('telefono', telNum.toString())
        .gte('vigencia', hoyIso)
        .limit(1);
    final filas = response as List;
    return filas.isEmpty;
  }

  Future<void> insertarProspecto(Map<String, dynamic> payload) async {
    await _ensureInitialized();
    await _client.from('prospectos').insert(payload);
  }

  Future<void> actualizarProspecto(int id, Map<String, dynamic> payload) async {
    await _ensureInitialized();
    await _client.from('prospectos').update(payload).eq('id', id);
  }

  Future<PaginaProspectos> fetchProspectos({
    required int pagina,
    required int porPagina,
    String busqueda = '',
  }) async {
    await _ensureInitialized();
    final termino = busqueda.trim();
    var query = _client
        .from('prospectos')
        .select(
          'id, prospecto, telefono, origen_prospecto, informacion, vigencia, usuario, created_at, usuario(nombres, apellidos)',
        );

    final rol = Sesion.instance.rol;
    if (rol != 1) {
      final userId = Sesion.instance.id;
      if (userId != null) {
        query = query.eq('usuario', userId);
      }
    }

    if (termino.isNotEmpty) {
      final condiciones = <String>[];
      condiciones.add('prospecto.ilike.%$termino%');
      if (RegExp(r'^\d+$').hasMatch(termino)) {
        condiciones.add('telefono::text.ilike.%$termino%');
      } else if (termino.isNotEmpty) {
        condiciones.add('telefono::text.ilike.%$termino%');
      }
      query = query.or(condiciones.join(','));
    }

    final respuesta = await query
        .order('id', ascending: false)
        .range(pagina * porPagina, pagina * porPagina + porPagina - 1)
        .count(CountOption.exact);

    final filas = respuesta.data as List;
    return PaginaProspectos(
      items: filas
          .map((row) => _mapProspecto(row as Map<String, dynamic>))
          .toList(),
      total: respuesta.count,
    );
  }

  ProspectoResumen _mapProspecto(Map<String, dynamic> row) {
    final usuario = row['usuario'];
    String creadoPor = '';
    int? usuarioId;
    if (usuario is Map<String, dynamic>) {
      final nombres = '${usuario['nombres'] ?? ''}';
      final apellidos = '${usuario['apellidos'] ?? ''}';
      creadoPor = [
        nombres,
        apellidos,
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
      usuarioId = usuario['id'] as int?;
    } else if (usuario is int) {
      usuarioId = usuario;
    }
    final telefono = row['telefono'];
    return ProspectoResumen(
      id: row['id'] as int,
      prospecto: '${row['prospecto'] ?? ''}',
      telefono: telefono == null ? '' : '$telefono',
      origenProspecto: '${row['origen_prospecto'] ?? ''}',
      informacion: '${row['informacion'] ?? ''}',
      vigencia: dmaDesdeIso(row['vigencia'] as String?),
      creadoPor: creadoPor,
      usuarioId: usuarioId,
      createdAt: '${row['created_at'] ?? ''}',
    );
  }

  ClienteResumen _mapCliente(Map<String, dynamic> row) {
    final prefijo = (row['prefijo'] as String?)?.trim() ?? '';
    final casada = (row['casada'] as String?)?.trim() ?? '';
    final partes = <String>[
      '${row['nombres'] ?? ''}',
      '${row['paterno'] ?? ''}',
      '${row['materno'] ?? ''}',
      if (prefijo.isNotEmpty && casada.isNotEmpty) '$prefijo $casada',
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final mt2 = row['mt2'];
    final fecha = row['fecha_form'] as String?;

    return ClienteResumen(
      id: row['id'] as int,
      nombreCompleto: partes.join(' '),
      urbanizacion: '${row['urbanizacion'] ?? ''}',
      uv: '${row['uv'] ?? ''}',
      mz: '${row['mz'] ?? ''}',
      lt: '${row['lt'] ?? ''}',
      cat: '${row['cat'] ?? ''}',
      mt2: mt2 == null ? '' : '$mt2'.replaceAll('.0', ''),
      fecha: fecha == null ? '' : dmaDesdeIso(fecha),
    );
  }
}
