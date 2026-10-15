import 'package:flutter/material.dart';

import '../services/cliente_service.dart';
import '../services/sesion.dart';
import '../theme/app_colors.dart';
import '../utils/upper_case_formatter.dart';

class CitaAddScreen extends StatefulWidget {
  const CitaAddScreen({super.key});

  @override
  State<CitaAddScreen> createState() => _CitaAddScreenState();
}

class _CitaAddScreenState extends State<CitaAddScreen> {
  static const _maxCupos = 10;

  final _formKey = GlobalKey<FormState>();
  final _nroContrato = TextEditingController();
  final _cliente = TextEditingController();
  final _fecha = TextEditingController();
  final _informacion = TextEditingController();

  static const _horarios = <(String, String)>[
    ('08:00', '08:45'),
    ('08:45', '09:30'),
    ('09:30', '10:15'),
    ('10:15', '11:00'),
    ('11:00', '11:45'),
    ('11:45', '12:30'),
    ('12:30', '13:15'),
    ('13:15', '14:00'),
    ('14:00', '14:45'),
    ('14:45', '15:30'),
    ('15:30', '16:15'),
    ('16:15', '17:00'),
    ('17:00', '17:45'),
    ('17:45', '18:30'),
  ];

  DateTime? _fechaSeleccionada;
  String? _horarioSeleccionado;
  int? _personalSeleccionado;

  List<PersonalCita> _personal = [];
  bool _cargandoPersonal = true;
  Map<String, int> _cupos = {};

  @override
  void initState() {
    super.initState();
    _cargarPersonal();
  }

  @override
  void dispose() {
    _nroContrato.dispose();
    _cliente.dispose();
    _fecha.dispose();
    _informacion.dispose();
    super.dispose();
  }

  Future<void> _cargarPersonal() async {
    try {
      final personal = await ClienteService.instance.fetchPersonalCitas();
      final ordenado = [...personal]
        ..sort((a, b) {
          final aSin = _esSinAsignar(a.funcionario);
          final bSin = _esSinAsignar(b.funcionario);
          if (aSin != bSin) return aSin ? -1 : 1;
          return a.funcionario.toLowerCase().compareTo(
            b.funcionario.toLowerCase(),
          );
        });
      if (!mounted) return;
      setState(() {
        _personal = ordenado;
        _personalSeleccionado = ordenado
            .where((p) => _esSinAsignar(p.funcionario))
            .firstOrNull
            ?.id;
        _cargandoPersonal = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoPersonal = false);
    }
  }

  bool _esSinAsignar(String funcionario) =>
      funcionario.trim().toUpperCase() == 'SIN ASIGNAR';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Nueva Cita',
          style: TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1000;
            final isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth < 1000;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSection(isDesktop, isTablet),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(bool isDesktop, bool isTablet) {
    final columns = isDesktop ? 3 : (isTablet ? 2 : 1);

    return Card(
      elevation: 2,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 28 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event_note_outlined,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Datos de la cita',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isDesktop ? 2.6 : (isTablet ? 2.8 : 4.4),
              children: [
                _buildNroContratoField(),
                _buildClienteField(),
                _buildFechaField(),
                _buildHorarioField(),
                _buildPersonalField(),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoField(),
          ],
        ),
      ),
    );
  }

  Widget _buildNroContratoField() {
    return TextFormField(
      controller: _nroContrato,
      inputFormatters: const [UpperCaseTextFormatter()],
      decoration: _fieldDecoration('Nro Contrato', Icons.numbers_outlined),
      validator: _requerido,
    );
  }

  Widget _buildClienteField() {
    return TextFormField(
      controller: _cliente,
      inputFormatters: const [UpperCaseTextFormatter()],
      decoration: _fieldDecoration('Cliente', Icons.person_outline),
      validator: _requerido,
    );
  }

  Widget _buildFechaField() {
    return TextFormField(
      controller: _fecha,
      readOnly: true,
      decoration:
          _fieldDecoration(
            'Fecha de la cita',
            Icons.calendar_month_outlined,
          ).copyWith(
            suffixIcon: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primaryBlue,
            ),
          ),
      onTap: _pickFecha,
      validator: _requerido,
    );
  }

  Widget _buildHorarioField() {
    final disponibles = [
      for (final horario in _horarios)
        if (!_estaLleno('${horario.$1} - ${horario.$2}'))
          '${horario.$1} - ${horario.$2}',
    ];
    return DropdownButtonFormField<String>(
      initialValue: _horarioSeleccionado,
      isExpanded: true,
      decoration: _fieldDecoration('Horario', Icons.schedule_outlined).copyWith(
        hintText: (_fecha.text.isNotEmpty && disponibles.isEmpty)
            ? 'No hay horarios disponibles para esta fecha'
            : null,
      ),
      items: [
        for (final label in disponibles)
          DropdownMenuItem(value: label, child: Text(label)),
      ],
      onChanged: (value) => setState(() => _horarioSeleccionado = value),
      validator: (value) {
        if (disponibles.isEmpty) return 'No hay horarios disponibles';
        return value == null ? 'Este campo es obligatorio' : null;
      },
    );
  }

  Widget _buildPersonalField() {
    return DropdownButtonFormField<int>(
      initialValue: _personalSeleccionado,
      isExpanded: true,
      decoration: _fieldDecoration(
        'Personal asignado',
        Icons.badge_outlined,
      ).copyWith(hintText: _cargandoPersonal ? 'Cargando personal...' : null),
      items: [
        for (final persona in _personal)
          DropdownMenuItem(
            value: persona.id,
            child: Text(
              persona.funcionario.isEmpty
                  ? 'Personal ${persona.id}'
                  : persona.funcionario,
            ),
          ),
      ],
      onChanged: _cargandoPersonal
          ? null
          : (value) {
              setState(() => _personalSeleccionado = value);
            },
      validator: (value) => value == null ? 'Este campo es obligatorio' : null,
    );
  }

  Widget _buildInfoField() {
    return TextFormField(
      controller: _informacion,
      maxLines: 5,
      textAlignVertical: TextAlignVertical.top,
      inputFormatters: const [UpperCaseTextFormatter()],
      decoration: _fieldDecoration(
        'Información extra',
        Icons.notes_outlined,
      ).copyWith(alignLabelWithHint: true),
    );
  }

  String? _requerido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primaryBlue),
    );
  }

  Widget _buildSubmitButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 600 ? 300.0 : double.infinity;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Guardar'),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _estaLleno(String horario) => (_cupos[horario] ?? 0) >= _maxCupos;

  Future<void> _pickFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha == null || !mounted) return;

    setState(() {
      _fechaSeleccionada = fecha;
      _fecha.text = _formatearFecha(fecha);
    });
    await _cargarCupos();
  }

  Future<void> _cargarCupos() async {
    if (_fechaSeleccionada == null) return;
    try {
      final cupos = await ClienteService.instance.contarCuposPorHorario(
        _isoFecha(_fechaSeleccionada!),
      );
      if (!mounted) return;
      setState(() {
        _cupos = cupos;
        if (_horarioSeleccionado != null && _estaLleno(_horarioSeleccionado!)) {
          _horarioSeleccionado = null;
        }
      });
      if (_horarioSeleccionado == null &&
          cupos.values.any((c) => c >= _maxCupos)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hay horarios llenos para esa fecha (10 citas).'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (_) {
      // Si falla la consulta, la validación de cupo se hace igual al guardar.
    }
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  String _isoFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  Map<String, dynamic> _buildCitaPayload() {
    final info = _informacion.text.trim();
    return <String, dynamic>{
      'contrato': _nroContrato.text.trim(),
      'cliente': _cliente.text.trim(),
      'fecha_cita': _isoFecha(_fechaSeleccionada!),
      'hora_cita': _horarioSeleccionado,
      'personal_asignado': _personalSeleccionado,
      'usuario': Sesion.instance.id,
      'informacion': info.isEmpty ? null : info,
    };
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fechaSeleccionada == null) return;

    if (Sesion.instance.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sesión no iniciada. Inicia sesión e inténtalo de nuevo.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );

    try {
      final cupos = await ClienteService.instance.contarCuposPorHorario(
        _isoFecha(_fechaSeleccionada!),
      );
      final actuales = cupos[_horarioSeleccionado] ?? 0;
      if (actuales >= _maxCupos) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El horario $_horarioSeleccionado ya tiene $_maxCupos citas. '
              'Elige otro horario.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await ClienteService.instance.insertarCita(_buildCitaPayload());
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita registrada correctamente'),
          backgroundColor: AppColors.mediumGreen,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar la cita: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
