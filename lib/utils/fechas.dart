String _pad(int value) => value.toString().padLeft(2, '0');

String? isoDesdeEdm(String dia, String mes, String anio) {
  final d = int.tryParse(dia.trim());
  final m = int.tryParse(mes.trim());
  final a = int.tryParse(anio.trim());
  if (d == null || m == null || a == null || a < 1000 || a > 9999) return null;
  if (m < 1 || m > 12) return null;
  final diasMes = DateTime(a, m + 1, 0).day;
  if (d < 1 || d > diasMes) return null;
  return '$a-${_pad(m)}-${_pad(d)}';
}

List<String>? edmDesdeIso(String? iso) {
  final trimmed = (iso ?? '').trim();
  if (trimmed.isEmpty) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;
  return [_pad(parsed.day), _pad(parsed.month), '${parsed.year}'];
}

String? isoDesdeDma(String? dma) {
  final trimmed = (dma ?? '').trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split('/');
  if (parts.length != 3) return null;
  return isoDesdeEdm(parts[0], parts[1], parts[2]);
}

String dmaDesdeIso(String? iso) {
  final parts = edmDesdeIso(iso);
  if (parts == null) return '';
  return '${parts[0]}/${parts[1]}/${parts[2]}';
}

int diasRestantesHasta(String? iso, {DateTime? desde}) {
  final parts = edmDesdeIso(iso);
  if (parts == null) return 0;

  final fecha = DateTime.utc(
    int.parse(parts[2]),
    int.parse(parts[1]),
    int.parse(parts[0]),
  );
  final hoy = desde ?? DateTime.now();
  final hoyUtc = DateTime.utc(hoy.year, hoy.month, hoy.day);

  return fecha.difference(hoyUtc).inDays;
}
