import 'dart:async';

import 'package:flutter/material.dart';

import '../services/cliente_service.dart';
import '../services/sesion.dart';
import '../theme/app_colors.dart';
import 'formulario_add_screen.dart';

class FormulariosScreen extends StatefulWidget {
  const FormulariosScreen({super.key});

  @override
  State<FormulariosScreen> createState() => _FormulariosScreenState();
}

class _FormulariosScreenState extends State<FormulariosScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Urbanizacion> _urbanizaciones = [];
  List<ClienteResumen> _items = [];
  int _total = 0;
  int _pagina = 0;
  int _porPagina = 10;
  bool _cargando = true;
  String? _error;

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
    _loadUrbanizaciones();
    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUrbanizaciones() async {
    try {
      final urbanizaciones = await ClienteService.instance
          .fetchUrbanizaciones();
      if (!mounted) return;
      setState(() {
        _urbanizaciones = urbanizaciones;
      });
    } catch (_) {
      // La lista funciona aunque no se carguen las urbanizaciones.
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final sesionId = Sesion.instance.id;
      final termino = _searchController.text.trim();
      final urbanizacionIds = <int>[
        for (final urbanizacion in _urbanizaciones)
          if (urbanizacion.nombre.toLowerCase().contains(termino.toLowerCase()))
            urbanizacion.id,
      ];
      final resultado = await ClienteService.instance.fetchClientes(
        usuarioId: sesionId ?? -1,
        pagina: _pagina,
        porPagina: _porPagina,
        busqueda: termino,
        urbanizacionIds: urbanizacionIds,
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

  String _nombreUrbanizacion(String idTexto) {
    final id = int.tryParse(idTexto);
    if (id == null) return idTexto;
    for (final urbanizacion in _urbanizaciones) {
      if (urbanizacion.id == id) return urbanizacion.nombre;
    }
    return idTexto;
  }

  Future<void> _abrirNuevoFormulario() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FormularioAddScreen()),
    );
    if (!mounted) return;
    _cargar();
  }

  Future<void> _onRowTap(ClienteResumen cliente) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FormularioAddScreen(clienteId: cliente.id),
      ),
    );
    if (!mounted) return;
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Formularios',
          style: TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        tooltip: 'Nuevo formulario',
        onPressed: _abrirNuevoFormulario,
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
        Expanded(child: sinRegistros ? _buildEmptyState() : _buildContent()),
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
          hintText: 'Buscar por nombre o urbanización',
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

  Widget _buildContent() {
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
              'Error al cargar los formularios:\n$_error',
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
    if (_items.isEmpty) {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;
        final table = _buildTable();
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
                        child: table,
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
    return DataTable(
      columnSpacing: 16,
      headingRowColor: WidgetStateProperty.all(AppColors.darkBlue),
      headingRowHeight: 44,
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.offWhite
            : null;
      }),
      columns: const [
        DataColumn(
          label: Text(
            'Nombre completo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Urbanización',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'UV',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'MZ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'LT',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'CAT',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'MT2',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Fecha',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            '',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
      rows: [
        for (final cliente in _items)
          DataRow(
            onSelectChanged: (_) => _onRowTap(cliente),
            cells: [
              DataCell(
                Text(
                  cliente.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(Text(_nombreUrbanizacion(cliente.urbanizacion))),
              DataCell(Text(cliente.uv)),
              DataCell(Text(cliente.mz)),
              DataCell(Text(cliente.lt)),
              DataCell(Text(cliente.cat)),
              DataCell(Text(cliente.mt2)),
              DataCell(Text(cliente.fecha)),
              DataCell(
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  tooltip: 'Modificar',
                  onPressed: () => _onRowTap(cliente),
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
                Icons.description_outlined,
                size: 44,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay formularios todavía',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona el botón + para crear tu primer formulario',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
