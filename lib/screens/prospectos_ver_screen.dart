import 'dart:async';

import 'package:flutter/material.dart';

import '../services/cliente_service.dart';
import '../services/sesion.dart';
import '../theme/app_colors.dart';
import 'prospectos_add_screen.dart';

class ProspectosVerScreen extends StatefulWidget {
  const ProspectosVerScreen({super.key});

  @override
  State<ProspectosVerScreen> createState() => _ProspectosVerScreenState();
}

class _ProspectosVerScreenState extends State<ProspectosVerScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ProspectoResumen> _items = [];
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
      final resultado = await ClienteService.instance.fetchProspectos(
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
      MaterialPageRoute(builder: (context) => const ProspectosAddScreen()),
    );
    if (!mounted) return;
    _cargar();
  }

  Future<void> _editar(ProspectoResumen prospecto) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProspectosAddScreen(prospecto: prospecto),
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
          'Prospectos',
          style: TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        tooltip: 'Nuevo prospecto',
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
          hintText: 'Buscar por nombre o teléfono',
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
            'Error al cargar los prospectos:\n$_error',
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
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
    return DataTable(
      columnSpacing: 16,
      headingRowColor: WidgetStateProperty.all(AppColors.darkBlue),
      headingRowHeight: 44,
      columns: const [
        DataColumn(label: Text('Nombre Completo', style: headerStyle)),
        DataColumn(label: Text('Teléfono', style: headerStyle)),
        DataColumn(label: Text('Origen cliente', style: headerStyle)),
        DataColumn(label: Text('Vigencia', style: headerStyle)),
        DataColumn(label: Text('Creado por', style: headerStyle)),
        DataColumn(label: Text('Acciones', style: headerStyle)),
      ],
      rows: [
        for (final p in _items)
          DataRow(
            cells: [
              DataCell(Text(p.prospecto)),
              DataCell(Text(p.telefono)),
              DataCell(Text(p.origenProspecto)),
              DataCell(Text(p.vigencia)),
              DataCell(Text(p.creadoPor)),
              DataCell(
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  tooltip: 'Modificar',
                  onPressed: () => _editar(p),
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
                  Icons.people_outline,
                  size: 44,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No hay prospectos todavía',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Presiona el botón + para agregar tu primer prospecto',
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
