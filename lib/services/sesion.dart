class Sesion {
  Sesion._();

  static final Sesion instance = Sesion._();

  int? id;
  String? nombres;
  String? apellidos;
  int? codigoAsesor;
  int? grupo;
  int? telefono;
  String? usuario;
  int? rol;

  bool get estaIniciada => id != null;

  void set(Map<String, dynamic> row) {
    id = row['id'] as int?;
    nombres = row['nombres'] as String?;
    apellidos = row['apellidos'] as String?;
    codigoAsesor = row['codigo_asesor'] as int?;
    grupo = row['grupo'] as int?;
    telefono = row['telefono'] as int?;
    usuario = row['usuario'] as String?;
    rol = row['rol'] as int?;
  }

  void clear() {
    id = null;
    nombres = null;
    apellidos = null;
    codigoAsesor = null;
    grupo = null;
    telefono = null;
    usuario = null;
    rol = null;
  }
}
