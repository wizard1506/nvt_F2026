import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/cliente_service.dart';
import '../services/sesion.dart';
import '../theme/app_colors.dart';
import '../utils/upper_case_formatter.dart';

class ProspectosAddScreen extends StatefulWidget {
  const ProspectosAddScreen({super.key, this.prospecto});

  final ProspectoResumen? prospecto;

  @override
  State<ProspectosAddScreen> createState() => _ProspectosAddScreenState();
}

class _ProspectosAddScreenState extends State<ProspectosAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _informacion = TextEditingController();

  static const _origenes = <String>[
    'REDES Y PAGINAS DEL ASESOR',
    'REDES DE LA EMPRESA',
    'RADIO',
    'REFERENCIADO',
    'OTRO',
  ];
  String? _origenSeleccionado;
  bool _guardando = false;

  bool get _esEdicion => widget.prospecto != null;

  @override
  void initState() {
    super.initState();
    final rol = Sesion.instance.rol;
    final puede = rol == 1 || rol == 4;
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
    if (_esEdicion) {
      final p = widget.prospecto!;
      _nombre.text = p.prospecto;
      _telefono.text = p.telefono;
      _informacion.text = p.informacion;
      if (_origenes.contains(p.origenProspecto)) {
        _origenSeleccionado = p.origenProspecto;
      }
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _informacion.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_guardando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_origenSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el origen del cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
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

    setState(() => _guardando = true);
    try {
      final informacion = _informacion.text.trim();

      if (_esEdicion) {
        await ClienteService.instance.actualizarProspecto(
          widget.prospecto!.id,
          {
            'prospecto': _nombre.text.trim(),
            'origen_prospecto': _origenSeleccionado,
            'informacion': informacion.isEmpty ? null : informacion,
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prospecto actualizado correctamente'),
            backgroundColor: AppColors.mediumGreen,
          ),
        );
        Navigator.of(context).pop(true);
        return;
      }

      final telefono = _telefono.text.trim();
      final puede = await ClienteService.instance.puedeRegistrarTelefono(
        telefono,
      );
      if (!puede) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este número de teléfono ya tiene una vigencia activa (menos de 15 días). Usa otro número.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _guardando = false);
        return;
      }

      final hoy = DateTime.now();
      final vigencia = DateTime(
        hoy.year,
        hoy.month,
        hoy.day,
      ).add(const Duration(days: 15));
      final vigenciaIso = _isoFecha(vigencia);
      final telefonoNum = BigInt.parse(telefono.replaceAll(RegExp(r'\D'), ''));

      await ClienteService.instance.insertarProspecto({
        'prospecto': _nombre.text.trim(),
        'telefono': telefonoNum.toString(),
        'origen_prospecto': _origenSeleccionado,
        'informacion': informacion.isEmpty ? null : informacion,
        'usuario': Sesion.instance.id,
        'vigencia': vigenciaIso,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prospecto registrado correctamente'),
          backgroundColor: AppColors.mediumGreen,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el prospecto: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _isoFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          _esEdicion ? 'Editar Prospecto' : 'Nuevo Prospecto',
          style: const TextStyle(
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
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      color: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                                  child: Icon(
                                    _esEdicion
                                        ? Icons.edit_outlined
                                        : Icons.person_add_alt_outlined,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Datos del prospecto',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildNombre(),
                            const SizedBox(height: 16),
                            _buildTelefono(),
                            const SizedBox(height: 16),
                            _buildOrigen(),
                            const SizedBox(height: 16),
                            _buildInfo(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSubmit(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNombre() {
    return TextFormField(
      controller: _nombre,
      inputFormatters: const [UpperCaseTextFormatter()],
      decoration: const InputDecoration(
        labelText: 'Nombre Completo',
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryBlue),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null,
    );
  }

  Widget _buildTelefono() {
    if (_esEdicion) {
      return TextFormField(
        controller: _telefono,
        enabled: false,
        decoration: const InputDecoration(
          labelText: 'Teléfono',
          prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryBlue),
          helperText: 'El teléfono no se puede modificar',
        ),
      );
    }
    return TextFormField(
      controller: _telefono,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Teléfono',
        prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryBlue),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Este campo es obligatorio';
        if (!RegExp(r'^\d+$').hasMatch(v.trim())) return 'Solo números';
        return null;
      },
    );
  }

  Widget _buildOrigen() {
    return DropdownButtonFormField<String>(
      initialValue: _origenSeleccionado,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Origen cliente',
        prefixIcon: Icon(Icons.source_outlined, color: AppColors.primaryBlue),
      ),
      items: [
        for (final o in _origenes) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: (v) => setState(() => _origenSeleccionado = v),
      validator: (v) => v == null ? 'Este campo es obligatorio' : null,
    );
  }

  Widget _buildInfo() {
    return TextFormField(
      controller: _informacion,
      maxLines: 5,
      textAlignVertical: TextAlignVertical.top,
      inputFormatters: const [UpperCaseTextFormatter()],
      decoration: const InputDecoration(
        labelText: 'Información extra',
        prefixIcon: Icon(Icons.notes_outlined, color: AppColors.primaryBlue),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSubmit() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _guardando ? null : _handleSave,
            child: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Guardar'),
          ),
        ),
      ),
    );
  }
}
