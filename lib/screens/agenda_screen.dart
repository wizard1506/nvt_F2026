import 'package:flutter/material.dart';

import '../services/cliente_service.dart';
import '../services/sesion.dart';
import '../theme/app_colors.dart';
import '../utils/estados_cita.dart';
import '../widgets/estado_badge.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  static const _meses = <String>[
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];
  static const _diasSemana = <String>[
    'LUN',
    'MAR',
    'MIÉ',
    'JUE',
    'VIE',
    'SÁB',
    'DOM',
  ];

  late DateTime _mesVisible;
  DateTime? _diaSeleccionado;
  Map<String, int> _conteos = {};
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final rol = Sesion.instance.rol;
    final puede = rol == 1 || rol == 5 || rol == 6;
    if (!puede) {
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
      return;
    }
    final hoy = DateTime.now();
    _mesVisible = DateTime(hoy.year, hoy.month);
    _diaSeleccionado = DateTime(hoy.year, hoy.month, hoy.day);
    _cargarConteos();
  }

  Future<void> _cargarConteos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final desde = DateTime(_mesVisible.year, _mesVisible.month, 1);
      final hasta = DateTime(_mesVisible.year, _mesVisible.month + 1, 0);
      final conteos = await ClienteService.instance.contarCitasPorDia(
        desde,
        hasta,
      );
      if (!mounted) return;
      setState(() {
        _conteos = conteos;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _cargando = false;
      });
    }
  }

  void _cambiarMes(int delta) {
    setState(() {
      _mesVisible = DateTime(_mesVisible.year, _mesVisible.month + delta, 1);
    });
    _cargarConteos();
  }

  void _irHoy() {
    final hoy = DateTime.now();
    setState(() {
      _mesVisible = DateTime(hoy.year, hoy.month);
      _diaSeleccionado = DateTime(hoy.year, hoy.month, hoy.day);
    });
    _cargarConteos();
  }

  Future<void> _abrirDia(DateTime dia) async {
    setState(() => _diaSeleccionado = dia);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: _CitasDelDiaSheet(fecha: dia),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Agenda',
          style: TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            _buildEncabezado(),
            const SizedBox(height: 8),
            _buildDiasSemana(),
            const SizedBox(height: 4),
            Expanded(child: _buildCalendario()),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezado() {
    return Row(
      children: [
        IconButton(
          onPressed: () => _cambiarMes(-1),
          icon: const Icon(Icons.chevron_left, color: AppColors.darkBlue),
          tooltip: 'Mes anterior',
        ),
        Expanded(
          child: Text(
            '${_meses[_mesVisible.month - 1]} ${_mesVisible.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBlue,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _cambiarMes(1),
          icon: const Icon(Icons.chevron_right, color: AppColors.darkBlue),
          tooltip: 'Mes siguiente',
        ),
        TextButton(onPressed: _irHoy, child: const Text('Hoy')),
      ],
    );
  }

  Widget _buildDiasSemana() {
    return Row(
      children: [
        for (final dia in _diasSemana)
          Expanded(
            child: Center(
              child: Text(
                dia,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendario() {
    final primerDia = DateTime(_mesVisible.year, _mesVisible.month, 1);
    final diasEnMes = DateTime(_mesVisible.year, _mesVisible.month + 1, 0).day;
    final desplazamiento = primerDia.weekday - 1;

    final celdas = <DateTime?>[];
    for (var i = 0; i < desplazamiento; i++) {
      celdas.add(null);
    }
    for (var d = 1; d <= diasEnMes; d++) {
      celdas.add(DateTime(_mesVisible.year, _mesVisible.month, d));
    }
    while (celdas.length % 7 != 0) {
      celdas.add(null);
    }
    final filas = celdas.length ~/ 7;

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error al cargar la agenda:\n$_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _cargarConteos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            for (var f = 0; f < filas; f++)
              Expanded(
                child: Row(
                  children: [
                    for (var c = 0; c < 7; c++)
                      Expanded(child: _buildCelda(celdas[f * 7 + c])),
                  ],
                ),
              ),
          ],
        ),
        if (_cargando)
          const Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCelda(DateTime? dia) {
    if (dia == null) {
      return const SizedBox.expand();
    }
    final conteo = _conteos[_isoFecha(dia)] ?? 0;
    final esHoy = _esMismoDia(dia, DateTime.now());
    final esSeleccionado =
        _diaSeleccionado != null && _esMismoDia(dia, _diaSeleccionado!);

    final Color fondo = esSeleccionado
        ? AppColors.primaryBlue
        : esHoy
        ? AppColors.lightBlue.withValues(alpha: 0.15)
        : AppColors.white;
    final Color colorTexto = esSeleccionado
        ? AppColors.white
        : AppColors.darkBlue;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _abrirDia(dia),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: esSeleccionado
                    ? AppColors.primaryBlue
                    : AppColors.lightBlue.withValues(alpha: 0.4),
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dia.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorTexto,
                  ),
                ),
                const Spacer(),
                if (conteo > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: esSeleccionado
                          ? AppColors.white
                          : AppColors.mediumGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      conteo == 1 ? '1 cita' : '$conteo citas',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: esSeleccionado
                            ? AppColors.primaryBlue
                            : AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _esMismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _isoFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }
}

class _CitasDelDiaSheet extends StatefulWidget {
  const _CitasDelDiaSheet({required this.fecha});

  final DateTime fecha;

  @override
  State<_CitasDelDiaSheet> createState() => _CitasDelDiaSheetState();
}

class _CitasDelDiaSheetState extends State<_CitasDelDiaSheet> {
  List<CitaResumen> _citas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final citas = await ClienteService.instance.fetchCitasDelDia(
        widget.fecha,
      );
      if (!mounted) return;
      setState(() {
        _citas = citas;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Citas · ${_fechaLegible()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error al cargar las citas:\n$_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_citas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No hay citas para este día',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _citas.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final cita = _citas[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.event_available_outlined,
            color: AppColors.primaryBlue,
          ),
          title: Text(
            cita.contrato.isEmpty ? '(Sin contrato)' : cita.contrato,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              if (cita.cliente.isNotEmpty) cita.cliente,
              cita.hora,
              if (cita.asignadoA.isNotEmpty) cita.asignadoA,
            ].join(' · '),
          ),
          trailing: EstadoBadge(
            estado: cita.estado,
            onTap: _puedeCambiarEstado ? () => _cambiarEstado(cita) : null,
          ),
        );
      },
    );
  }

  bool get _puedeCambiarEstado {
    final rol = Sesion.instance.rol;
    return rol == 1 || rol == 5;
  }

  Future<void> _cambiarEstado(CitaResumen cita) async {
    final estadoActual = cita.estado.trim().toUpperCase();
    final nuevoEstado = siguienteEstadoCita(estadoActual);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );

    try {
      await ClienteService.instance.actualizarEstadoCita(cita.id, nuevoEstado);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a $nuevoEstado'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () async {
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                ),
              );
              try {
                await ClienteService.instance.actualizarEstadoCita(
                  cita.id,
                  estadoActual.isEmpty ? 'PENDIENTE' : estadoActual,
                );
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                _cargar();
              } catch (error) {
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo deshacer el cambio: $error'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
          ),
        ),
      );
      _cargar();
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar el estado: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _fechaLegible() {
    final dia = widget.fecha.day.toString().padLeft(2, '0');
    final mes = widget.fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${widget.fecha.year}';
  }
}
