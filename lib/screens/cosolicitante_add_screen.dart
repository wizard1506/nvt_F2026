import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../services/cliente_service.dart';
import '../services/form_generator_service.dart';
import '../services/sesion.dart';
import '../theme/app_colors.dart';
import '../utils/fechas.dart';
import '../utils/upper_case_formatter.dart';

class CosolicitanteAddScreen extends StatefulWidget {
  const CosolicitanteAddScreen({super.key, this.cosolicitanteId});

  final int? cosolicitanteId;

  @override
  State<CosolicitanteAddScreen> createState() => _CosolicitanteAddScreenState();
}

class _CosolicitanteAddScreenState extends State<CosolicitanteAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _generator = FormGeneratorService();

  bool get _esEdicion => widget.cosolicitanteId != null;
  bool _editListo = false;

  static const _fieldKeys = <String>[
    'tipo_relacion',
    'paterno',
    'materno',
    'nombres',
    'casada',
    'prefijo',
    'tipo_identificacion',
    'documento',
    'extension',
    'fecha_nacimiento',
    'sexo',
    'estado_civil',
    'nivel_estudio',
    'profesion',
    'nacionalidad',
    'pais',
    'dpto',
    'telf_fijo',
    'telf_movil',
    'telf_fijo_oficina',
    'telf_movil_oficina',
    'correo',
    'lugar_trabajo',
    'direccion',
    'rubro',
    'ingresos',
    'moneda_ingresos',
  ];

  static const _prefijos = <String>['NINGUNO', 'VDA DE', 'DE'];
  static const _tipoIdentificacion = <String>[
    'Carnet de Identidad',
    'Pasaporte',
    'Carnet Extranjero',
  ];
  static const _extensiones = <String>[
    '--',
    'SC',
    'LP',
    'CB',
    'PO',
    'CH',
    'TJ',
    'OR',
    'BE',
    'PA',
  ];
  static const _sexos = <String>['Masculino', 'Femenino'];
  static const _estadosCiviles = <String>[
    'Soltero(a)',
    'Casado(a)',
    'Divorciado(a)',
    'Viudo(a)',
  ];
  static const _nivelesEstudio = <String>[
    'Ninguno',
    'Primaria',
    'Secundaria',
    'Tecnico Medio',
    'Tecnico Superior',
    'Licenciatura',
  ];
  static const _departamentos = <String>[
    '--',
    'Santa Cruz',
    'La Paz',
    'Cochabamba',
    'Beni',
    'Pando',
    'Oruro',
    'Potosi',
    'Tarija',
    'Chuquisaca',
  ];
  static const _monedasIngresos = <String>['Bs.', '\$u\$'];

  @override
  void initState() {
    super.initState();
    for (final key in _fieldKeys) {
      _controllers[key] = TextEditingController();
    }
    _c('prefijo').text = 'NINGUNO';
    _c('tipo_identificacion').text = 'Carnet de Identidad';
    _c('extension').text = '--';
    _c('estado_civil').text = 'Soltero(a)';
    _c('sexo').text = 'Masculino';
    _c('nivel_estudio').text = 'Ninguno';
    _c('dpto').text = '--';
    _c('moneda_ingresos').text = 'Bs.';
    if (_esEdicion) {
      _inicializarEdicion();
    }
  }

  Future<void> _inicializarEdicion() async {
    try {
      final row = await ClienteService.instance.fetchCosolicitantePorId(
        widget.cosolicitanteId!,
      );
      if (!mounted) return;
      if (row == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró el co-solicitante a editar.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      final rol = Sesion.instance.rol;
      final esSupervisor = rol == 1 || rol == 2;
      if (!esSupervisor) {
        final duenio = row['usuario'];
        final duenioId = duenio is Map ? duenio['id'] : duenio;
        if (duenioId != Sesion.instance.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No tienes permiso para editar este co-solicitante.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
          return;
        }
      }

      _aplicarDatos(row);
      setState(() => _editListo = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar el co-solicitante: $error'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _aplicarDatos(Map<String, dynamic> row) {
    String s(dynamic value) {
      if (value == null) return '';
      if (value is double && value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return '$value';
    }

    const textos = <String>[
      'tipo_relacion',
      'paterno',
      'materno',
      'nombres',
      'casada',
      'profesion',
      'nacionalidad',
      'pais',
      'telf_fijo',
      'telf_movil',
      'telf_fijo_oficina',
      'telf_movil_oficina',
      'correo',
      'lugar_trabajo',
      'direccion',
      'rubro',
      'ingresos',
    ];
    for (final key in textos) {
      _c(key).text = s(row[key]);
    }

    _c('fecha_nacimiento').text = dmaDesdeIso(
      row['fecha_nacimiento'] as String?,
    );

    void asignarDropdown(String key, String valor, List<String> opciones) {
      final texto = s(row[key]).trim();
      _c(key).text = opciones.contains(texto) ? texto : valor;
    }

    asignarDropdown('prefijo', 'NINGUNO', _prefijos);
    asignarDropdown(
      'tipo_identificacion',
      'Carnet de Identidad',
      _tipoIdentificacion,
    );
    asignarDropdown('extension', '--', _extensiones);
    asignarDropdown('estado_civil', 'Soltero(a)', _estadosCiviles);
    asignarDropdown('sexo', 'Masculino', _sexos);
    asignarDropdown('nivel_estudio', 'Ninguno', _nivelesEstudio);
    asignarDropdown('dpto', '--', _departamentos);
    asignarDropdown('moneda_ingresos', 'Bs.', _monedasIngresos);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _c(String key) => _controllers[key]!;

  @override
  Widget build(BuildContext context) {
    final titulo = _esEdicion
        ? 'Editar Co-Solicitante'
        : 'Nuevo Co-Solicitante';
    if (_esEdicion && !_editListo) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: Text(
            titulo,
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          titulo,
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
                    _buildSection(
                      const Icon(
                        Icons.family_restroom,
                        color: AppColors.primaryBlue,
                      ),
                      'Relación y datos personales',
                      isDesktop,
                      isTablet,
                      [
                        _buildTextField(
                          'tipo_relacion',
                          'Tipo relación con el titular',
                          Icons.people_alt_outlined,
                        ),
                        _buildTextField(
                          'paterno',
                          'Apellido Paterno',
                          Icons.badge_outlined,
                        ),
                        _buildTextField(
                          'materno',
                          'Apellido Materno',
                          Icons.badge_outlined,
                        ),
                        _buildTextField(
                          'nombres',
                          'Nombres',
                          Icons.person_outline,
                        ),
                        _buildTextField(
                          'casada',
                          'Apellido de Casada',
                          Icons.favorite_border,
                        ),
                        _buildDropdown('prefijo', 'Prefijo', _prefijos),
                        _buildDropdown(
                          'tipo_identificacion',
                          'Tipo de Identificación',
                          _tipoIdentificacion,
                        ),
                        _buildTextField(
                          'documento',
                          'Número de Documento',
                          Icons.credit_card_outlined,
                        ),
                        _buildDropdown('extension', 'Extensión', _extensiones),
                        _buildDateField(),
                        _buildDropdown('sexo', 'Sexo', _sexos),
                        _buildDropdown(
                          'estado_civil',
                          'Estado Civil',
                          _estadosCiviles,
                        ),
                        _buildDropdown(
                          'nivel_estudio',
                          'Nivel de Estudio',
                          _nivelesEstudio,
                        ),
                        _buildTextField(
                          'profesion',
                          'Profesión / Ocupación',
                          Icons.work_outline,
                        ),
                        _buildTextField(
                          'nacionalidad',
                          'Nacionalidad',
                          Icons.flag_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.place_outlined,
                        color: AppColors.primaryBlue,
                      ),
                      'Localización',
                      isDesktop,
                      isTablet,
                      [
                        _buildTextField('pais', 'País', Icons.public),
                        _buildDropdown('dpto', 'Departamento', _departamentos),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.phone_iphone_outlined,
                        color: AppColors.mediumGreen,
                      ),
                      'Contacto',
                      isDesktop,
                      isTablet,
                      [
                        _buildTextField(
                          'telf_fijo',
                          'Teléfono Fijo',
                          Icons.phone_outlined,
                          TextInputType.phone,
                        ),
                        _buildTextField(
                          'telf_movil',
                          'Teléfono Móvil',
                          Icons.smartphone_outlined,
                          TextInputType.phone,
                        ),
                        _buildTextField(
                          'telf_fijo_oficina',
                          'Teléfono Fijo Oficina',
                          Icons.phone_outlined,
                          TextInputType.phone,
                        ),
                        _buildTextField(
                          'telf_movil_oficina',
                          'Teléfono Móvil Oficina',
                          Icons.smartphone_outlined,
                          TextInputType.phone,
                        ),
                        _buildTextField(
                          'correo',
                          'Correo Electrónico',
                          Icons.mail_outline,
                          TextInputType.emailAddress,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.business_outlined,
                        color: AppColors.mediumGreen,
                      ),
                      'Datos Laborales',
                      isDesktop,
                      isTablet,
                      [
                        _buildTextField(
                          'lugar_trabajo',
                          'Lugar de Trabajo',
                          Icons.apartment_outlined,
                        ),
                        _buildTextField(
                          'direccion',
                          'Dirección',
                          Icons.map_outlined,
                        ),
                        _buildTextField(
                          'rubro',
                          'Rubro',
                          Icons.category_outlined,
                        ),
                        _buildTextField(
                          'ingresos',
                          'Ingresos',
                          Icons.attach_money_outlined,
                          TextInputType.number,
                        ),
                        _buildDropdown(
                          'moneda_ingresos',
                          'Moneda de Ingresos',
                          _monedasIngresos,
                        ),
                      ],
                    ),
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

  Widget _buildDateField() {
    return TextFormField(
      controller: _c('fecha_nacimiento'),
      readOnly: true,
      decoration: _fieldDecoration('Fecha de Nacimiento', Icons.cake_outlined)
          .copyWith(
            suffixIcon: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primaryBlue,
            ),
          ),
      onTap: () => _pickDate(context),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _c('fecha_nacimiento').text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Widget _buildSection(
    Icon icon,
    String title,
    bool isDesktop,
    bool isTablet,
    List<Widget> fields,
  ) {
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
                  child: icon,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
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
              children: fields,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String key,
    String label,
    IconData icon, [
    TextInputType? keyboardType,
  ]) {
    return TextFormField(
      controller: _c(key),
      keyboardType: keyboardType,
      inputFormatters: key == 'correo'
          ? null
          : const [UpperCaseTextFormatter()],
      decoration: _fieldDecoration(label, icon),
    );
  }

  Widget _buildDropdown(String key, String label, List<String> options) {
    return DropdownButtonFormField<String>(
      initialValue: _c(key).text.isEmpty ? null : _c(key).text,
      isExpanded: true,
      decoration: _fieldDecoration(
        label,
        Icons.arrow_drop_down_circle_outlined,
      ),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _c(key).text = value ?? '';
        });
      },
    );
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

  Map<String, dynamic> _buildCosolicitantePayload({
    bool incluirUsuario = true,
  }) {
    String? registro(String key) {
      final value = _c(key).text.trim();
      return (value.isEmpty || value == '--' || value == 'NINGUNO')
          ? null
          : value;
    }

    return <String, dynamic>{
      'tipo_relacion': registro('tipo_relacion'),
      'paterno': registro('paterno'),
      'materno': registro('materno'),
      'nombres': registro('nombres'),
      'casada': registro('casada'),
      'prefijo': registro('prefijo'),
      'tipo_identificacion': registro('tipo_identificacion'),
      'documento': registro('documento'),
      'extension': registro('extension'),
      'fecha_nacimiento': isoDesdeDma(_c('fecha_nacimiento').text),
      'sexo': registro('sexo'),
      'estado_civil': registro('estado_civil'),
      'nivel_estudio': registro('nivel_estudio'),
      'profesion': registro('profesion'),
      'nacionalidad': registro('nacionalidad'),
      'pais': registro('pais'),
      'dpto': registro('dpto'),
      'telf_fijo': registro('telf_fijo'),
      'telf_movil': registro('telf_movil'),
      'telf_fijo_oficina': registro('telf_fijo_oficina'),
      'telf_movil_oficina': registro('telf_movil_oficina'),
      'correo': registro('correo'),
      'lugar_trabajo': registro('lugar_trabajo'),
      'direccion': registro('direccion'),
      'rubro': registro('rubro'),
      'ingresos': registro('ingresos'),
      'moneda_ingresos': registro('moneda_ingresos'),
      if (incluirUsuario) 'usuario': Sesion.instance.id,
    };
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
      if (_esEdicion) {
        await ClienteService.instance.actualizarCosolicitante(
          widget.cosolicitanteId!,
          _buildCosolicitantePayload(incluirUsuario: false),
        );
      } else {
        await ClienteService.instance.insertarCosolicitante(
          _buildCosolicitantePayload(),
        );
      }
      final data = <String, String>{
        for (final key in _fieldKeys)
          key: _c(key).text.trim() == 'NINGUNO' && key == 'prefijo'
              ? ''
              : _c(key).text.trim(),
        'user_nombres': Sesion.instance.nombres ?? '',
        'user_apellidos': Sesion.instance.apellidos ?? '',
      };
      final result = await _generator.generateCosolAndSave(data);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? 'Co-solicitante actualizado correctamente'
                : 'Co-solicitante registrado correctamente',
          ),
          backgroundColor: AppColors.mediumGreen,
        ),
      );
      _showGeneratedDialog(result);
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar el co-solicitante: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showGeneratedDialog(GeneratedForm result) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Co-solicitante generado',
          style: TextStyle(color: AppColors.darkBlue),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.mediumGreen),
                SizedBox(width: 8),
                Text('PDF creado correctamente'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Guardado en:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            SelectableText(
              result.path,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (previewContext) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Vista previa'),
                      backgroundColor: AppColors.darkBlue,
                      foregroundColor: Colors.white,
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(previewContext).pop(),
                      ),
                    ),
                    body: PdfPreview(
                      build: (_) => result.bytes,
                      canChangeOrientation: false,
                      canChangePageFormat: true,
                      useActions: true,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.preview_outlined),
            label: const Text('Vista previa'),
          ),
        ],
      ),
    );
  }
}
