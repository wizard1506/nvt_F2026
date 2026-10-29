import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/reporte_excel_service.dart';
import '../services/reporte_export_service.dart';
import '../services/reporte_service.dart';
import '../services/sesion.dart';
import '../theme/app_colors.dart';

enum TipoReporte { prospectos, citas }

extension TipoReporteInfo on TipoReporte {
  String get titulo => switch (this) {
    TipoReporte.prospectos => 'Reporte Prospectos',
    TipoReporte.citas => 'Reporte Citas Clientes',
  };

  String get descripcion => switch (this) {
    TipoReporte.prospectos =>
      'Prospectos registrados en el rango de fechas seleccionado',
    TipoReporte.citas => 'Citas registradas en el rango de fechas seleccionado',
  };

  IconData get icono => switch (this) {
    TipoReporte.prospectos => Icons.people_outline,
    TipoReporte.citas => Icons.event_note_outlined,
  };

  IconData get iconoExcel => switch (this) {
    TipoReporte.prospectos => Icons.table_view_outlined,
    TipoReporte.citas => Icons.table_chart_outlined,
  };

  String get nombreArchivo => switch (this) {
    TipoReporte.prospectos => 'prospectos',
    TipoReporte.citas => 'citas',
  };
}

class ReporteFechasScreen extends StatefulWidget {
  const ReporteFechasScreen({super.key, required this.tipo});

  final TipoReporte tipo;

  @override
  State<ReporteFechasScreen> createState() => _ReporteFechasScreenState();
}

class _ReporteFechasScreenState extends State<ReporteFechasScreen> {
  late DateTime _fechaInicial;
  late DateTime _fechaFinal;
  late final TextEditingController _inicialController;
  late final TextEditingController _finalController;
  bool _descargando = false;
  bool _compartiendo = false;
  _ReporteGenerado? _cache;

  bool get _ocupado => _descargando || _compartiendo;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _fechaInicial = DateTime(hoy.year, hoy.month);
    _fechaFinal = DateTime(hoy.year, hoy.month, hoy.day);
    _inicialController = TextEditingController(text: _dma(_fechaInicial));
    _finalController = TextEditingController(text: _dma(_fechaFinal));

    if (Sesion.instance.rol != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes permiso para acceder a esta sección'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _inicialController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha({required bool inicial}) async {
    final actual = inicial ? _fechaInicial : _fechaFinal;
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: inicial ? DateTime(2000) : _fechaInicial,
      lastDate: inicial ? _fechaFinal : DateTime(2100),
    );
    if (seleccionada == null) return;

    setState(() {
      if (inicial) {
        _fechaInicial = seleccionada;
        _inicialController.text = _dma(seleccionada);
      } else {
        _fechaFinal = seleccionada;
        _finalController.text = _dma(seleccionada);
      }
      _cache = null;
    });
  }

  Future<void> _descargar() async {
    if (_ocupado) return;
    setState(() => _descargando = true);
    try {
      final reporte = await _obtenerReporte();
      if (!mounted) return;
      final destino = await ReporteExportService.instance.descargar(
        nombre: reporte.nombre,
        bytes: reporte.bytes,
      );
      if (!mounted) return;
      if (destino == null) {
        _mostrarMensaje('No se guardó el archivo', error: true);
      } else {
        _mostrarMensaje('Excel guardado correctamente', error: false);
      }
    } on _SinDatosException {
      if (!mounted) return;
      _mostrarMensaje('No hay registros en el rango seleccionado', error: true);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje('Error al generar el reporte: $error', error: true);
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  Future<void> _compartir() async {
    if (_ocupado) return;
    setState(() => _compartiendo = true);
    try {
      final reporte = await _obtenerReporte();
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origen = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      await ReporteExportService.instance.compartir(
        nombre: reporte.nombre,
        bytes: reporte.bytes,
        origen: origen,
      );
    } on _SinDatosException {
      if (!mounted) return;
      _mostrarMensaje('No hay registros en el rango seleccionado', error: true);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje('Error al compartir el reporte: $error', error: true);
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  Future<_ReporteGenerado> _obtenerReporte() async {
    if (_cache != null &&
        _mismaFecha(_cache!.fechaInicial, _fechaInicial) &&
        _mismaFecha(_cache!.fechaFinal, _fechaFinal)) {
      return _cache!;
    }

    final inicio = _fechaInicial;
    final fin = _fechaFinal;
    final nombre =
        'reporte_${widget.tipo.nombreArchivo}_'
        '${_fechaArchivo(inicio)}_a_${_fechaArchivo(fin)}';

    final Uint8List bytes;
    if (widget.tipo == TipoReporte.prospectos) {
      final filas = await ReporteService.instance.fetchProspectos(inicio, fin);
      if (filas.isEmpty) throw const _SinDatosException();
      bytes = ReporteExcelService.prospectos(filas);
    } else {
      final filas = await ReporteService.instance.fetchCitas(inicio, fin);
      if (filas.isEmpty) throw const _SinDatosException();
      bytes = ReporteExcelService.citas(filas);
    }

    final reporte = _ReporteGenerado(
      bytes: bytes,
      nombre: nombre,
      fechaInicial: inicio,
      fechaFinal: fin,
    );
    _cache = reporte;
    return reporte;
  }

  bool _mismaFecha(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dma(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  String _fechaArchivo(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  void _mostrarMensaje(String mensaje, {required bool error}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.orange : AppColors.mediumGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puedeCompartir = ReporteExportService.instance.puedeCompartir;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          widget.tipo.titulo,
          style: const TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : 24,
              vertical: 32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.darkBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.tipo.icono,
                            color: AppColors.darkBlue,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.tipo.descripcion,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Card(
                      elevation: isDesktop ? 8 : 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: AppColors.white,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 40 : 24,
                          vertical: isDesktop ? 36 : 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Rango de fechas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Se incluyen los registros desde la fecha inicial '
                              'hasta la fecha final, ambos días incluidos.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _inicialController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Fecha inicial',
                                prefixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              onTap: _ocupado
                                  ? null
                                  : () => _seleccionarFecha(inicial: true),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _finalController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Fecha final',
                                prefixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              onTap: _ocupado
                                  ? null
                                  : () => _seleccionarFecha(inicial: false),
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: _ocupado ? null : _descargar,
                              icon: _descargando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(widget.tipo.iconoExcel),
                              label: Text(
                                _descargando
                                    ? 'Generando Excel...'
                                    : 'Descargar Excel',
                              ),
                            ),
                            if (puedeCompartir) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _ocupado ? null : _compartir,
                                icon: _compartiendo
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.share_outlined),
                                label: Text(
                                  _compartiendo
                                      ? 'Generando Excel...'
                                      : 'Compartir Excel',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReporteGenerado {
  const _ReporteGenerado({
    required this.bytes,
    required this.nombre,
    required this.fechaInicial,
    required this.fechaFinal,
  });

  final Uint8List bytes;
  final String nombre;
  final DateTime fechaInicial;
  final DateTime fechaFinal;
}

class _SinDatosException implements Exception {
  const _SinDatosException();
}
