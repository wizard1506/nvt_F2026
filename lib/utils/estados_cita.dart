const List<String> estadosCita = ['PENDIENTE', 'ATENDIDA', 'CANCELADO'];

String siguienteEstadoCita(String actual) {
  switch (actual.trim().toUpperCase()) {
    case 'PENDIENTE':
      return 'ATENDIDA';
    case 'ATENDIDA':
      return 'CANCELADO';
    case 'CANCELADO':
      return 'PENDIENTE';
    default:
      return 'PENDIENTE';
  }
}
