import 'dart:async';

import 'package:flutter/material.dart';

import '../services/cliente_service.dart';
import '../theme/app_colors.dart';
import '../utils/fechas.dart';
import 'cosolicitante_add_screen.dart';

class CosolicitantesScreen extends StatefulWidget {
  const CosolicitantesScreen({super.key});

  @override
  State<CosolicitantesScreen> createState() => _CosolicitantesScreenState();
}

class _CosolicitantesScreenState extends State<CosolicitantesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<CosolicitanteResumen> _items = [];
  int _total = 0;
  int _pagina = 0;
  int _porPagina = 10;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultado = await ClienteService.instance.fetchCosolicitantes(
        pagina: _pagina,
        porPagina: _porPagina,
        busqueda: _searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _items = resultado.items;
        _total = resultado.total;
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _pagina = 0);
      _cargar();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _pagina = 0);
    _cargar();
  }

  void _cambiarPagina(int pagina) {
    if (pagina < 0 || pagina >= _totalPaginas) return;
    setState(() => _pagina = pagina);
    _cargar();
  }

  int get _totalPaginas => (_total / _porPagina).ceil().clamp(1, 1 << 31);

  Future<void> _abrirNuevo() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CosolicitanteAddScreen()),
    );
    if (!mounted) return;
    _cargar();
  }

  Future<void> _editar(CosolicitanteResumen cosolicitante) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CosolicitanteAddScreen(cosolicitanteId: cosolicitante.id),
      ),
    );
    if (!mounted) return;
    _cargar();
  }

  Future<void> _abrirDetalle(CosolicitanteResumen cosolicitante) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: _DetalleCosolicitanteSheet(cosolicitante: cosolicitante),
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
          'Co-Solicitantes',
          style: TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        tooltip: 'Nuevo co-solicitante',
        onPressed: _abrirNuevo,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final sinRegistros =
        !_cargando &&
        _error == null &&
        _total == 0 &&
        _items.isEmpty &&
        _searchController.text.trim().isEmpty;
    return Column(
      children: [
        _buildSearchField(),
        Expanded(child: sinRegistros ? _buildEmptyState() : _buildResultado()),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o documento',
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: _clearSearch,
                ),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightBlue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildResultado() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }
    if (_error != null) {
      return _buildError();
    }
    if (_items.isEmpty) {
      return _buildSinResultados();
    }
    return _buildContent();
  }

  Widget _buildSinResultados() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Sin resultados para la búsqueda',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Error al cargar los co-solicitantes:\n$_error',
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

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;
        return RefreshIndicator(
          onRefresh: _cargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1200 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: isDesktop ? 0 : constraints.maxWidth - 32,
                        ),
                        child: _buildTable(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPaginationBar(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable() {
    const headerStyle = TextStyle(
      color: AppColors.white,
      fontWeight: FontWeight.bold,
    );
    return DataTable(
      showCheckboxColumn: false,
      columnSpacing: 16,
      headingRowColor: WidgetStateProperty.all(AppColors.darkBlue),
      headingRowHeight: 44,
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.offWhite
            : null;
      }),
      columns: const [
        DataColumn(label: Text('Nombre', style: headerStyle)),
        DataColumn(label: Text('Documento', style: headerStyle)),
        DataColumn(label: Text('Móvil', style: headerStyle)),
        DataColumn(label: Text('Creado por', style: headerStyle)),
        DataColumn(label: Text('Acciones', style: headerStyle)),
      ],
      rows: [
        for (final c in _items)
          DataRow(
            onSelectChanged: (_) => _abrirDetalle(c),
            cells: [
              DataCell(
                Text(
                  c.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(Text(c.documento)),
              DataCell(Text(c.telefonoMovil)),
              DataCell(Text(c.creadoPor)),
              DataCell(
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  tooltip: 'Modificar',
                  onPressed: () => _editar(c),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaginationBar() {
    final totalPaginas = _totalPaginas < 1 ? 1 : _totalPaginas;
    final desde = _total == 0 ? 0 : _pagina * _porPagina + 1;
    final hasta = (_pagina * _porPagina + _porPagina).clamp(0, _total);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _pagina > 0 ? () => _cambiarPagina(_pagina - 1) : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Anterior',
        ),
        Text(
          'Página ${_pagina + 1} de $totalPaginas · $_total registros'
          '${_total == 0 ? '' : ' ($desde–$hasta)'}',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        IconButton(
          onPressed: _pagina < totalPaginas - 1
              ? () => _cambiarPagina(_pagina + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Siguiente',
        ),
        const SizedBox(width: 8),
        _buildPorPaginaSelector(),
      ],
    );
  }

  Widget _buildPorPaginaSelector() {
    return PopupMenuButton<int>(
      tooltip: 'Filas por página',
      initialValue: _porPagina,
      onSelected: (value) {
        setState(() {
          _porPagina = value;
          _pagina = 0;
        });
        _cargar();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 10, child: Text('10 por página')),
        PopupMenuItem(value: 20, child: Text('20 por página')),
        PopupMenuItem(value: 50, child: Text('50 por página')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_porPagina',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_add_outlined,
                  size: 44,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No hay co-solicitantes todavía',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Presiona el botón + para agregar tu primer co-solicitante',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalleCosolicitanteSheet extends StatefulWidget {
  const _DetalleCosolicitanteSheet({required this.cosolicitante});

  final CosolicitanteResumen cosolicitante;

  @override
  State<_DetalleCosolicitanteSheet> createState() =>
      _DetalleCosolicitanteSheetState();
}

class _DetalleCosolicitanteSheetState
    extends State<_DetalleCosolicitanteSheet> {
  Map<String, dynamic>? _data;
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
      final data = await ClienteService.instance.fetchCosolicitantePorId(
        widget.cosolicitante.id,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
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

  String _valor(String key) {
    final valor = '${_data?[key] ?? ''}'.trim();
    if (valor.isEmpty ||
        valor == 'null' ||
        valor == '--' ||
        valor == 'NINGUNO') {
      return '';
    }
    return valor;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error al cargar el co-solicitante:\n$_error',
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
        ),
      );
    }

    final ingresos = _valor('ingresos');
    final moneda = _valor('moneda_ingresos');
    final creado = widget.cosolicitante.creadoPor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          widget.cosolicitante.nombreCompleto,
          style: const TextStyle(
            color: AppColors.darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _seccion('Relación y datos personales', [
          _fila('Tipo de relación', _valor('tipo_relacion')),
          _fila('Nombres', _valor('nombres')),
          _fila('Apellido paterno', _valor('paterno')),
          _fila('Apellido materno', _valor('materno')),
          _fila('Apellido de casada', _valor('casada')),
          _fila('Prefijo', _valor('prefijo')),
          _fila('Tipo de identificación', _valor('tipo_identificacion')),
          _fila('Documento', _valor('documento')),
          _fila('Extensión', _valor('extension')),
          _fila('Fecha de nacimiento', dmaDesdeIso(_valor('fecha_nacimiento'))),
          _fila('Sexo', _valor('sexo')),
          _fila('Estado civil', _valor('estado_civil')),
          _fila('Nivel de estudio', _valor('nivel_estudio')),
          _fila('Profesión', _valor('profesion')),
          _fila('Nacionalidad', _valor('nacionalidad')),
        ]),
        _seccion('Localización', [
          _fila('País', _valor('pais')),
          _fila('Departamento', _valor('dpto')),
        ]),
        _seccion('Contacto', [
          _fila('Teléfono fijo', _valor('telf_fijo')),
          _fila('Teléfono móvil', _valor('telf_movil')),
          _fila('Teléfono fijo oficina', _valor('telf_fijo_oficina')),
          _fila('Teléfono móvil oficina', _valor('telf_movil_oficina')),
          _fila('Correo electrónico', _valor('correo')),
        ]),
        _seccion('Datos laborales', [
          _fila('Lugar de trabajo', _valor('lugar_trabajo')),
          _fila('Dirección', _valor('direccion')),
          _fila('Rubro', _valor('rubro')),
          _fila(
            'Ingresos',
            ingresos.isEmpty
                ? ''
                : (moneda.isEmpty ? ingresos : '$ingresos $moneda'),
          ),
        ]),
        _seccion('Registro', [
          _fila('Creado por', creado),
          _fila(
            'Fecha de registro',
            dmaDesdeIso(
              widget.cosolicitante.createdAt.isEmpty
                  ? null
                  : widget.cosolicitante.createdAt,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _seccion(String titulo, List<Widget> filas) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                size: 16,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  titulo.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...filas,
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              etiqueta,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              valor.isEmpty ? '—' : valor,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
