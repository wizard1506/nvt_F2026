import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../services/cliente_service.dart';
import '../services/form_generator_service.dart';
import '../services/sesion.dart';
import '../theme/app_colors.dart';
import '../utils/fechas.dart';
import '../utils/upper_case_formatter.dart';

class FormularioAddScreen extends StatefulWidget {
  const FormularioAddScreen({super.key});

  @override
  State<FormularioAddScreen> createState() => _FormularioAddScreenState();
}

class _FormularioAddScreenState extends State<FormularioAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _generator = FormGeneratorService();

  static const _fieldKeys = <String>[
    // Tipo de participación
    'cargo_publico_detalle',
    'familiar_cargo_publico_detalle',
    'tercero_nombre',
    // Fecha del formulario
    'dia',
    'mes',
    'anio',
    // Datos del lote
    'urbanizacion',
    'proyecto',
    'uv',
    'mz',
    'lt',
    'cat',
    'mt2',
    'cantidad_plazo',
    // Datos personales
    'paterno',
    'materno',
    'nombres',
    'casada',
    'prefijo',
    'documento',
    'extension',
    'nacionalidad',
    'estado_civil',
    'nivel_estudio',
    'profesion',
    'tipo_documento',
    'fecha_nacimiento', 'sexo',
    // Datos de vivienda
    'tipo_vivienda',
    'tenencia',
    'costo_vivienda',
    'moneda_vivienda',
    'propietario',
    'telf_propietario',
    // Datos de localización
    'pais', 'dpto', 'ciudad', 'zona', 'barrio', 'avenida', 'calle', 'numero',
    'ubicacion',
    // Datos de contacto
    'telf_movil', 'movil_oficina', 'telf_fijo', 'fijo_oficina', 'correo',
    // Datos laborales
    'empresa', 'direccion', 'rubro', 'ingresos', 'moneda_ingresos',
    // Referencias
    'referencia1',
    'relacion1',
    'telf_ref1',
    'referencia2',
    'relacion2',
    'telf_ref2',
    // Observaciones
    'obs1', 'obs2',
  ];

  String? _plazoContado;
  String? _generarReserva;
  String? _tipoParticipacion;
  String? _cargoPublico;
  String? _cargoFamiliar;
  String? _compraTercero;
  Uint8List? _mapaImagen;
  bool _saving = false;
  List<Urbanizacion> _urbanizaciones = [];
  int? _urbanizacionId;

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
    for (final key in _fieldKeys) {
      _controllers[key] = TextEditingController();
    }
    final now = DateTime.now();
    _c('dia').text = now.day.toString().padLeft(2, '0');
    _c('mes').text = now.month.toString().padLeft(2, '0');
    _c('anio').text = now.year.toString();
    _c('prefijo').text = 'NINGUNO';
    _c('tipo_documento').text = 'Carnet de Identidad';
    _c('extension').text = '--';
    _c('estado_civil').text = 'Soltero(a)';
    _c('sexo').text = 'Masculino';
    _c('nivel_estudio').text = 'Ninguno';
    _c('tipo_vivienda').text = 'Dpto';
    _c('tenencia').text = 'Propia';
    _c('dpto').text = '--';
    _c('moneda_vivienda').text = 'Bs';
    _c('moneda_ingresos').text = 'Bs';
    _loadUrbanizaciones();
  }

  Future<void> _loadUrbanizaciones() async {
    try {
      final urbanizaciones = await ClienteService.instance
          .fetchUrbanizaciones();
      if (!mounted) return;
      setState(() {
        _urbanizaciones = urbanizaciones;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron cargar las urbanizaciones: $error'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Nuevo Formulario',
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
            final width = constraints.maxWidth;
            final isDesktop = width >= 1000;
            final isTablet = width >= 600 && width < 1000;

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
                        Icons.how_to_reg_outlined,
                        color: AppColors.primaryBlue,
                      ),
                      'Tipo de Participación',
                      isDesktop,
                      isTablet,
                      [
                        DropdownButtonFormField<String>(
                          initialValue: _tipoParticipacion,
                          isExpanded: true,
                          decoration: _fieldDecoration(
                            'Tipo de Participación',
                            Icons.badge_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Titular',
                              child: Text('Titular'),
                            ),
                            DropdownMenuItem(
                              value: 'Apoderado',
                              child: Text('Apoderado'),
                            ),
                            DropdownMenuItem(
                              value: 'Comprador por cuenta de tercero',
                              child: Text(
                                'Comprador por cuenta de tercero',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _tipoParticipacion = value;
                            });
                          },
                        ),
                        _buildSiNo(
                          label: '¿Ocupa o ha ocupado algún cargo público en los últimos 5 años?',
                          value: _cargoPublico,
                          detailKey: 'cargo_publico_detalle',
                          detailLabel: '¿Qué cargo?',
                          detailIcon: Icons.work_outline,
                          detailError: 'Indica el cargo',
                          onChanged: (value) {
                            setState(() {
                              _cargoPublico = value;
                            });
                          },
                        ),
                        _buildSiNo(
                          label: '¿Algún familiar suyo ocupa o ha ocupado algún cargo público en los últimos 5 años?',
                          value: _cargoFamiliar,
                          detailKey: 'familiar_cargo_publico_detalle',
                          detailLabel: '¿Qué cargo?',
                          detailIcon: Icons.work_outline,
                          detailError: 'Indica el cargo',
                          onChanged: (value) {
                            setState(() {
                              _cargoFamiliar = value;
                            });
                          },
                        ),
                        _buildSiNo(
                          label: '¿La compra es para un tercero?',
                          value: _compraTercero,
                          detailKey: 'tercero_nombre',
                          detailLabel: 'Nombre del tercero',
                          detailIcon: Icons.person_outline,
                          detailError: 'Indica el nombre del tercero',
                          onChanged: (value) {
                            setState(() {
                              _compraTercero = value;
                            });
                          },
                        ),
                      ],
                      stacked: true,
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.location_city_outlined,
                        color: AppColors.primaryBlue,
                      ),
                      'Datos del Lote',
                      isDesktop,
                      isTablet,
                      [
                        _buildUrbanizacionField(),
                        _buildTextField(
                          'proyecto',
                          'Proyecto',
                          Icons.home_work_outlined,
                        ),
                        _buildTextField('uv', 'U.V.', Icons.grid_3x3),
                        _buildTextField(
                          'mz',
                          'Manzana (MZ)',
                          Icons.crop_square,
                        ),
                        _buildTextField('lt', 'Lote (LT)', Icons.crop_16_9),
                        _buildTextField(
                          'cat',
                          'Categoría (CAT)',
                          Icons.category_outlined,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _plazoContado,
                          isExpanded: true,
                          decoration: _fieldDecoration(
                            'Forma de Pago',
                            Icons.payments_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'PLAZO',
                              child: Text('A Plazo'),
                            ),
                            DropdownMenuItem(
                              value: 'CONTADO',
                              child: Text('Contado'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _plazoContado = value;
                            });
                          },
                        ),
                        _buildTextField(
                          'mt2',
                          'Superficie (m²)',
                          Icons.square_foot_outlined,
                          TextInputType.number,
                        ),
                        _buildTextField(
                          'cantidad_plazo',
                          'Cantidad de Plazos',
                          Icons.date_range_outlined,
                          TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.description_outlined,
                        color: AppColors.primaryBlue,
                      ),
                      'Formularios adicionales',
                      isDesktop,
                      isTablet,
                      [
                        DropdownButtonFormField<String>(
                          initialValue: _generarReserva,
                          isExpanded: true,
                          decoration: _fieldDecoration(
                            '¿Generar formulario reserva?',
                            Icons.handshake_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'SI', child: Text('Si')),
                            DropdownMenuItem(value: 'NO', child: Text('No')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _generarReserva = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.mediumGreen,
                      ),
                      'Fecha del Formulario',
                      isDesktop,
                      isTablet,
                      [
                        _buildTextField(
                          'dia',
                          'Día',
                          Icons.calendar_view_day_outlined,
                          TextInputType.number,
                        ),
                        _buildTextField(
                          'mes',
                          'Mes',
                          Icons.calendar_view_month_outlined,
                          TextInputType.number,
                        ),
                        _buildTextField(
                          'anio',
                          'Ano',
                          Icons.event_outlined,
                          TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.person_outline,
                        color: AppColors.primaryBlue,
                      ),
                      'Datos Personales',
                      isDesktop,
                      isTablet,
                      [
                        _buildTextField(
                          'nombres',
                          'Nombres',
                          Icons.badge_outlined,
                        ),
                        _buildTextField(
                          'paterno',
                          'Apellido Paterno',
                          Icons.person_outline,
                        ),
                        _buildTextField(
                          'materno',
                          'Apellido Materno',
                          Icons.person_outline,
                        ),
                        _buildDropdown('prefijo', 'Prefijo', [
                          'NINGUNO',
                          'VDA DE',
                          'DE',
                        ]),
                        _buildTextField(
                          'casada',
                          'Apellido de Casada',
                          Icons.favorite_outline,
                        ),
                        _buildDropdown('tipo_documento', 'Tipo de Documento', [
                          'Carnet de Identidad',
                          'Pasaporte',
                          'Carnet Extranjero',
                        ]),
                        _buildTextField(
                          'documento',
                          'N° Documento',
                          Icons.badge_outlined,
                        ),
                        _buildDropdown('extension', 'Extensión', [
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
                        ]),
                        _buildTextField(
                          'nacionalidad',
                          'Nacionalidad',
                          Icons.public,
                        ),
                        _buildDateField(),
                        _buildDropdown('estado_civil', 'Estado Civil', [
                          'Soltero(a)',
                          'Casado(a)',
                          'Divorciado(a)',
                          'Viudo(a)',
                        ]),
                        _buildDropdown('sexo', 'Sexo', [
                          'Masculino',
                          'Femenino',
                        ]),
                        _buildDropdown('nivel_estudio', 'Nivel de Estudio', [
                          'Ninguno',
                          'Primaria',
                          'Secundaria',
                          'Tecnico Medio',
                          'Tecnico Superior',
                          'Licenciatura',
                        ]),
                        _buildTextField(
                          'profesion',
                          'Profesión',
                          Icons.work_outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.home_outlined,
                        color: AppColors.mediumGreen,
                      ),
                      'Datos de Vivienda',
                      isDesktop,
                      isTablet,
                      [
                        _buildDropdown('tipo_vivienda', 'Tipo de Vivienda', [
                          'Dpto',
                          'Casa',
                          'Cuarto',
                          'Terreno',
                          'Otro',
                        ]),
                        _buildDropdown('tenencia', 'Tenencia', [
                          'Propia',
                          'Alquiler',
                          'Anticretico',
                          'Otro',
                        ]),
                        _buildTextField(
                          'costo_vivienda',
                          'Costo de Vivienda',
                          Icons.attach_money,
                        ),
                        _buildDropdown('moneda_vivienda', 'Moneda', [
                          'Bs',
                          'USD',
                        ]),
                        _buildTextField(
                          'propietario',
                          'Propietario',
                          Icons.verified_user_outlined,
                        ),
                        _buildTextField(
                          'telf_propietario',
                          'Teléfono Propietario',
                          Icons.phone_outlined,
                          TextInputType.phone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.place_outlined,
                        color: AppColors.primaryBlue,
                      ),
                      'Datos de Localización',
                      isDesktop,
                      isTablet,
                      [
                        _buildTextField('pais', 'País', Icons.public),
                        _buildDropdown('dpto', 'Departamento', [
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
                        ]),
                        _buildTextField(
                          'ciudad',
                          'Ciudad',
                          Icons.location_city_outlined,
                        ),
                        _buildTextField('zona', 'Zona', Icons.map_outlined),
                        _buildTextField(
                          'barrio',
                          'Barrio',
                          Icons.house_outlined,
                        ),
                        _buildTextField(
                          'avenida',
                          'Avenida',
                          Icons.signpost_outlined,
                        ),
                        _buildTextField('calle', 'Calle', Icons.straighten),
                        _buildTextField(
                          'numero',
                          'Número',
                          Icons.numbers,
                          TextInputType.number,
                          _onlyDigits,
                        ),
                        _buildTextField(
                          'ubicacion',
                          'Link (URL) del croquis del mapa',
                          Icons.link,
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickMapaImagen,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text(
                            'Adjuntar croquis / imagen del mapa',
                          ),
                        ),
                        if (_mapaImagen != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Container(
                                  height: 120,
                                  width: double.infinity,
                                  color: Colors.black12,
                                  child: Image.memory(
                                    _mapaImagen!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Quitar imagen',
                                    onPressed: () {
                                      setState(() {
                                        _mapaImagen = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.phone_iphone_outlined,
                        color: AppColors.mediumGreen,
                      ),
                      'Datos de Contacto',
                      isDesktop,
                      isTablet,
                      [
                        _buildTextField(
                          'telf_movil',
                          'Celular',
                          Icons.smartphone_outlined,
                          TextInputType.phone,
                        ),
                        _buildTextField(
                          'movil_oficina',
                          'Celular de Oficina',
                          Icons.business_outlined,
                          TextInputType.phone,
                        ),
                        _buildTextField(
                          'telf_fijo',
                          'Teléfono Fijo',
                          Icons.phone_outlined,
                          TextInputType.phone,
                        ),
                        _buildTextField(
                          'fijo_oficina',
                          'Fijo de Oficina',
                          Icons.business_outlined,
                          TextInputType.phone,
                        ),
                        _buildTextField(
                          'correo',
                          'Correo Electrónico',
                          Icons.email_outlined,
                          TextInputType.emailAddress,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.business_outlined,
                        color: AppColors.primaryBlue,
                      ),
                      'Datos Laborales',
                      isDesktop,
                      isTablet,
                      [
                        _buildTextField(
                          'empresa',
                          'Empresa',
                          Icons.apartment_outlined,
                        ),
                        _buildTextField(
                          'direccion',
                          'Dirección',
                          Icons.location_on_outlined,
                        ),
                        _buildTextField(
                          'rubro',
                          'Rubro',
                          Icons.storefront_outlined,
                        ),
                        _buildTextField(
                          'ingresos',
                          'Ingresos',
                          Icons.payments_outlined,
                          TextInputType.number,
                        ),
                        _buildDropdown(
                          'moneda_ingresos',
                          'Moneda de Ingresos',
                          ['Bs', 'USD'],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.groups_outlined,
                        color: AppColors.mediumGreen,
                      ),
                      'Referencias Personales',
                      isDesktop,
                      isTablet,
                      [
                        _buildTextField(
                          'referencia1',
                          'Referencia 1',
                          Icons.person_outline,
                        ),
                        _buildTextField(
                          'relacion1',
                          'Relación 1',
                          Icons.family_restroom,
                        ),
                        _buildTextField(
                          'telf_ref1',
                          'Teléfono Ref. 1',
                          Icons.phone_outlined,
                          TextInputType.phone,
                        ),
                        _buildTextField(
                          'referencia2',
                          'Referencia 2',
                          Icons.person_outline,
                        ),
                        _buildTextField(
                          'relacion2',
                          'Relación 2',
                          Icons.family_restroom,
                        ),
                        _buildTextField(
                          'telf_ref2',
                          'Teléfono Ref. 2',
                          Icons.phone_outlined,
                          TextInputType.phone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      const Icon(
                        Icons.notes_outlined,
                        color: AppColors.primaryBlue,
                      ),
                      'Observaciones',
                      isDesktop,
                      isTablet,
                      [
                        _buildMultilineField('obs1', 'Observación 1', 3),
                        _buildMultilineField('obs2', 'Observación 2', 3),
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
    List<Widget> fields, {
    bool stacked = false,
  }) {
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
            if (stacked)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < fields.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    fields[i],
                  ],
                ],
              )
            else
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
    String? Function(String?)? validator,
  ]) {
    return TextFormField(
      controller: _c(key),
      keyboardType: keyboardType,
      decoration: _fieldDecoration(label, icon),
      validator: validator,
      inputFormatters: (key == 'correo' || key == 'ubicacion')
          ? null
          : const [UpperCaseTextFormatter()],
    );
  }

  String? _onlyDigits(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Solo números';
    }
    return null;
  }

  Widget _buildUrbanizacionField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _urbanizacionId,
            decoration: _fieldDecoration('Urbanización', Icons.map_outlined),
            items: [
              for (final urbanizacion in _urbanizaciones)
                DropdownMenuItem(
                  value: urbanizacion.id,
                  child: Text(
                    urbanizacion.nombre,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            validator: (value) =>
                value == null ? 'Selecciona la urbanización' : null,
            onChanged: (value) {
              setState(() {
                _urbanizacionId = value;
                String nombre = '';
                for (final urbanizacion in _urbanizaciones) {
                  if (urbanizacion.id == value) nombre = urbanizacion.nombre;
                }
                _c('urbanizacion').text = nombre;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _createUrbanizacion,
          tooltip: 'Nueva urbanización',
          icon: const Icon(
            Icons.add_circle_outline,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Future<void> _createUrbanizacion() async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => const _NuevaUrbanizacionDialog(),
    );
    if (nombre == null || nombre.trim().isEmpty || !mounted) return;
    try {
      final id = await ClienteService.instance.insertarUrbanizacion(
        nombre.trim(),
      );
      if (!mounted) return;
      setState(() {
        _urbanizaciones = [
          ..._urbanizaciones,
          Urbanizacion(id: id, nombre: nombre.trim()),
        ]..sort((a, b) => a.nombre.compareTo(b.nombre));
        _urbanizacionId = id;
        _c('urbanizacion').text = nombre.trim();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear la urbanización: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildMultilineField(String key, String label, int lines) {
    return TextFormField(
      controller: _c(key),
      maxLines: lines,
      inputFormatters: const [UpperCaseTextFormatter()],
      decoration: _fieldDecoration(
        label,
        Icons.notes_outlined,
      ).copyWith(alignLabelWithHint: true),
    );
  }

  Widget _buildSiNo({
    required String label,
    required String? value,
    required String detailKey,
    required String detailLabel,
    required IconData detailIcon,
    required String detailError,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: _fieldDecoration(label, Icons.help_outline),
          items: const [
            DropdownMenuItem(value: 'SI', child: Text('Si')),
            DropdownMenuItem(value: 'NO', child: Text('No')),
          ],
          onChanged: onChanged,
        ),
        if (value == 'SI') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _c(detailKey),
            inputFormatters: const [UpperCaseTextFormatter()],
            decoration: _fieldDecoration(detailLabel, detailIcon),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? detailError : null,
          ),
        ],
      ],
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
                onPressed: _saving ? null : _handleSave,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar Formulario'),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _invalidLink(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.isAbsolute ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return 'El link debe ser una URL válida (ej. https://...).';
    }
    return null;
  }

  Future<void> _pickMapaImagen() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _mapaImagen = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo seleccionar la imagen: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    if (_saving) return;
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

    final link = _c('ubicacion').text.trim();
    final urlError = link.isEmpty ? null : _invalidLink(link);
    if (urlError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(urlError), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_mapaImagen == null && link.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El link y el croquis del mapa van juntos: adjunta la imagen o quita el link.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_mapaImagen != null && link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Para adjuntar el croquis del mapa, indica el link (URL) del mapa.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final payload = _buildClientePayload();
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha del formulario no es válida.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );

    try {
      await ClienteService.instance.insertarCliente(payload);
      final data = <String, String>{
        for (final key in _fieldKeys)
          key: _c(key).text.trim() == 'NINGUNO' && key == 'prefijo'
              ? ''
              : _c(key).text.trim(),
        'plazo_contado': ?_plazoContado,
        'generar_reserva': ?_generarReserva,
        'user_nombres': Sesion.instance.nombres ?? '',
        'user_apellidos': Sesion.instance.apellidos ?? '',
        'user_codigo_asesor': Sesion.instance.codigoAsesor?.toString() ?? '',
        'tipo_participacion': _tipoParticipacion ?? '',
        'cargo_publico': _cargoPublico ?? '',
        'familiar_cargo_publico': _cargoFamiliar ?? '',
        'compra_tercero': _compraTercero ?? '',
      };
      final result = await _generator.generateAndSave(
        data,
        mapaImagen: _mapaImagen,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showGeneratedDialog(result);
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el formulario: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic>? _buildClientePayload() {
    double? aDouble(String key) => double.tryParse(_c(key).text.trim());

    int? anInt(String key) => int.tryParse(_c(key).text.trim());

    String? registro(String key) {
      final value = _c(key).text.trim();
      return (value.isEmpty || value == '--' || value == 'NINGUNO')
          ? null
          : value;
    }

    final fechaForm = isoDesdeEdm(
      _c('dia').text,
      _c('mes').text,
      _c('anio').text,
    );
    if (fechaForm == null) return null;

    final ubicacion = _c('ubicacion').text.trim();

    return <String, dynamic>{
      'fecha_form': fechaForm,
      'tipo_participacion': _tipoParticipacion,
      'cargo_publico': _cargoPublico,
      'cargo_publico_detalle': _cargoPublico == 'SI'
          ? registro('cargo_publico_detalle')
          : null,
      'familiar_cargo_publico': _cargoFamiliar,
      'familiar_cargo_publico_detalle': _cargoFamiliar == 'SI'
          ? registro('familiar_cargo_publico_detalle')
          : null,
      'compra_tercero': _compraTercero,
      'tercero_nombre': _compraTercero == 'SI'
          ? registro('tercero_nombre')
          : null,
      'paterno': registro('paterno'),
      'materno': registro('materno'),
      'nombres': registro('nombres'),
      'casada': registro('casada'),
      'prefijo': registro('prefijo'),
      'documento': registro('documento'),
      'extension': registro('extension'),
      'tipo_documento': registro('tipo_documento'),
      'fecha_nacimiento': isoDesdeDma(_c('fecha_nacimiento').text),
      'sexo': registro('sexo'),
      'estado_civil': registro('estado_civil'),
      'nivel_estudio': registro('nivel_estudio'),
      'profesion': registro('profesion'),
      'nacionalidad': registro('nacionalidad'),
      'tipo_vivienda': registro('tipo_vivienda'),
      'tenencia': registro('tenencia'),
      'costo_vivienda': aDouble('costo_vivienda'),
      'moneda_vivienda': registro('moneda_vivienda'),
      'propietario': registro('propietario'),
      'telf_propietario': registro('telf_propietario'),
      'pais': registro('pais'),
      'dpto': registro('dpto'),
      'ciudad': registro('ciudad'),
      'zona': registro('zona'),
      'barrio': registro('barrio'),
      'avenida': registro('avenida'),
      'calle': registro('calle'),
      'numero': anInt('numero'),
      'ubicacion': ubicacion.isEmpty ? null : ubicacion,
      'telf_fijo': registro('telf_fijo'),
      'telf_movil': registro('telf_movil'),
      'fijo_oficina': registro('fijo_oficina'),
      'movil_oficina': registro('movil_oficina'),
      'correo': registro('correo'),
      'empresa': registro('empresa'),
      'direccion': registro('direccion'),
      'rubro': registro('rubro'),
      'ingresos': aDouble('ingresos'),
      'moneda_ingresos': registro('moneda_ingresos'),
      'referencia1': registro('referencia1'),
      'relacion1': registro('relacion1'),
      'telf_ref1': registro('telf_ref1'),
      'referencia2': registro('referencia2'),
      'relacion2': registro('relacion2'),
      'telf_ref2': registro('telf_ref2'),
      'obs1': registro('obs1'),
      'obs2': registro('obs2'),
      'usuario': Sesion.instance.id,
      'urbanizacion': _urbanizacionId,
      'proyecto': registro('proyecto'),
      'uv': registro('uv'),
      'mz': registro('mz'),
      'lt': registro('lt'),
      'cat': registro('cat'),
      'mt2': aDouble('mt2'),
      'cantidad_plazo': anInt('cantidad_plazo'),
      'plazo_contado': _plazoContado,
    };
  }

  void _showGeneratedDialog(GeneratedForm result) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Formulario generado',
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

class _NuevaUrbanizacionDialog extends StatefulWidget {
  const _NuevaUrbanizacionDialog();

  @override
  State<_NuevaUrbanizacionDialog> createState() =>
      _NuevaUrbanizacionDialogState();
}

class _NuevaUrbanizacionDialogState extends State<_NuevaUrbanizacionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _agregar() {
    final nombre = _controller.text.trim();
    if (nombre.isEmpty) return;
    Navigator.of(context).pop(nombre);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Urbanización'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: const [UpperCaseTextFormatter()],
        decoration: const InputDecoration(
          labelText: 'Nombre',
          hintText: 'Ej. Torreluz',
        ),
        onSubmitted: (_) => _agregar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _agregar, child: const Text('Agregar')),
      ],
    );
  }
}
