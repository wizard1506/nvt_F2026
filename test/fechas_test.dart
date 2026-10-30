import 'package:flutter_test/flutter_test.dart';
import 'package:novitierra_f/utils/fechas.dart';

void main() {
  test('diasRestantesHasta calcula días calendario', () {
    final hoy = DateTime(2026, 10, 30, 18, 45);

    expect(diasRestantesHasta('2026-10-30', desde: hoy), 0);
    expect(diasRestantesHasta('2026-10-31', desde: hoy), 1);
    expect(diasRestantesHasta('2026-11-14', desde: hoy), 15);
    expect(diasRestantesHasta('2026-10-29', desde: hoy), -1);
  });

  test('diasRestantesHasta devuelve 0 para fechas inválidas', () {
    expect(diasRestantesHasta(null), 0);
    expect(diasRestantesHasta(''), 0);
    expect(diasRestantesHasta('sin-fecha'), 0);
  });
}
