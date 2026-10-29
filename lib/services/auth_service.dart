import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'sesion.dart';

class Grupo {
  const Grupo({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory Grupo.fromJson(Map<String, dynamic> json) =>
      Grupo(id: json['id'] as int, nombre: (json['nombre'] as String?) ?? '');
}

String _hashPassword(String password) =>
    BCrypt.hashpw(password, BCrypt.gensalt());

enum LoginResult { ok, usuarioNoExiste, passwordIncorrecta }

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _ensureInitialized() => SupabaseConfig.ensureInitialized();

  Future<LoginResult> iniciarSesion(String usuario, String password) async {
    await _ensureInitialized();
    final row = await _client
        .from('usuario')
        .select(
          'id, nombres, apellidos, codigo_asesor, grupo, telefono, usuario, rol, password',
        )
        .eq('usuario', usuario)
        .maybeSingle();
    if (row == null) return LoginResult.usuarioNoExiste;
    final hash = row['password'] as String?;
    if (hash == null || hash.isEmpty || !BCrypt.checkpw(password, hash)) {
      return LoginResult.passwordIncorrecta;
    }
    Sesion.instance.set(row);
    return LoginResult.ok;
  }

  Future<List<Grupo>> fetchGrupos() async {
    await _ensureInitialized();
    final response = await _client
        .from('grupos')
        .select('id, nombre')
        .order('nombre');
    return (response as List)
        .map((row) => Grupo.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<bool> usuarioExiste(String usuario) async {
    await _ensureInitialized();
    final response = await _client
        .from('usuario')
        .select('id')
        .eq('usuario', usuario)
        .limit(1);
    return (response as List).isNotEmpty;
  }

  Future<bool> actualizarPasswordPorUsuario(
    String usuario,
    String password,
  ) async {
    await _ensureInitialized();
    final hash = await compute(_hashPassword, password);
    final response = await _client
        .from('usuario')
        .update({'password': hash})
        .eq('usuario', usuario)
        .select('id');
    return (response as List).isNotEmpty;
  }

  Future<bool> codigoAsesorExiste(int codigoAsesor) async {
    await _ensureInitialized();
    final response = await _client
        .from('usuario')
        .select('id')
        .eq('codigo_asesor', codigoAsesor)
        .limit(1);
    return (response as List).isNotEmpty;
  }

  Future<void> registrarUsuario({
    required String nombres,
    required String apellidos,
    required int codigoAsesor,
    required int grupo,
    required int telefono,
    required String usuario,
    required String password,
  }) async {
    await _ensureInitialized();
    final hash = await compute(_hashPassword, password);
    await _client.from('usuario').insert({
      'nombres': nombres,
      'apellidos': apellidos,
      'codigo_asesor': codigoAsesor,
      'grupo': grupo,
      'telefono': telefono,
      'usuario': usuario,
      'password': hash,
      'rol': SupabaseConfig.defaultRolAsesor,
    });
  }
}
