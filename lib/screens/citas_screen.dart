import 'dart:async';

import 'package:flutter/material.dart';

import '../services/cliente_service.dart';
import '../theme/app_colors.dart';
import 'cita_add_screen.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<CitaResumen> _items = [];
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
      final resultado = await ClienteService.instance.fetchCitas(
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

  Future<void> _abrirNuevaCita() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const CitaAddScreen()));
    if (!mounted) return;
    _cargar();
  }

  Future<void> _asignarPersonal(CitaResumen cita) async {
    final personalId = await showDialog<int>(
      context: context,
      builder: (_) => _AsignarPersonalDialog(cita: cita),
    );
    if (personalId == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );

    try {
      await ClienteService.instance.actualizarPersonalCita(cita.id, personalId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal asignado correctamente'),
          backgroundColor: AppColors.mediumGreen,
        ),
      );
      _cargar();
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar el personal: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Citas',
          style: TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        tooltip: 'Nueva cita',
        onPressed: _abrirNuevaCita,
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
          hintText: 'Buscar por contrato, cliente, personal o creador',
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
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.offWhite
            : null;
      }),
      columns: const [
        DataColumn(label: Text('Nro Contrato', style: headerStyle)),
        DataColumn(label: Text('Cliente', style: headerStyle)),
        DataColumn(label: Text('Fecha', style: headerStyle)),
        DataColumn(label: Text('Hora', style: headerStyle)),
        DataColumn(label: Text('Personal asignado', style: headerStyle)),
        DataColumn(label: Text('Creado por', style: headerStyle)),
        DataColumn(label: Text('Acciones', style: headerStyle)),
      ],
      rows: [
        for (final cita in _items)
          DataRow(
            cells: [
              DataCell(
                Text(
                  cita.contrato,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(Text(cita.cliente)),
              DataCell(Text(cita.fecha)),
              DataCell(Text(cita.hora)),
              DataCell(Text(cita.personal)),
              DataCell(Text(cita.creadoPor)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () => _asignarPersonal(cita),
                  icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                  label: const Text('Asignar'),
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
                  Icons.event_available_outlined,
                  size: 44,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No hay citas todavía',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Presiona el botón + para agregar tu primera cita',
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

class _AsignarPersonalDialog extends StatefulWidget {
  const _AsignarPersonalDialog({required this.cita});

  final CitaResumen cita;

  @override
  State<_AsignarPersonalDialog> createState() => _AsignarPersonalDialogState();
}

class _AsignarPersonalDialogState extends State<_AsignarPersonalDialog> {
  List<PersonalCita> _personal = [];
  int? _seleccionado;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _seleccionado = widget.cita.personalId;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
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

  bool _esSinAsignar(String funcionario) =>
      funcionario.trim().toUpperCase() == 'SIN ASIGNAR';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar personal'),
      content: SizedBox(width: 360, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_cargando || _seleccionado == null)
              ? null
              : () => Navigator.of(context).pop(_seleccionado),
          child: const Text('Asignar'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Error al cargar el personal:\n$_error',
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
      );
    }
    if (_personal.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No hay personal registrado.'),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _seleccionado,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Personal asignado',
        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryBlue),
      ),
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
      onChanged: (value) => setState(() => _seleccionado = value),
    );
  }
}
