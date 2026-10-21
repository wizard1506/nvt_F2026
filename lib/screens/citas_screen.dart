import 'dart:async';

import 'package:flutter/material.dart';

import '../services/cliente_service.dart';
import '../services/sesion.dart';
import '../theme/app_colors.dart';
import '../utils/estados_cita.dart';
import '../utils/upper_case_formatter.dart';
import '../widgets/estado_badge.dart';
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

  bool get _puedeAsignar {
    final rol = Sesion.instance.rol;
    return rol == 1 || rol == 5;
  }

  bool get _puedeEliminar {
    final rol = Sesion.instance.rol;
    return rol == 1 || rol == 5;
  }

  bool get _puedeCambiarEstado {
    final rol = Sesion.instance.rol;
    return rol == 1 || rol == 5;
  }

  Future<void> _eliminarCita(CitaResumen cita) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: Text(
          '¿Seguro que deseas eliminar la cita'
          '${cita.contrato.isEmpty ? '' : ' del contrato ${cita.contrato}'}? '
          'Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );

    try {
      await ClienteService.instance.eliminarCita(cita.id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita eliminada correctamente'),
          backgroundColor: AppColors.mediumGreen,
        ),
      );
      _cargar();
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la cita: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _abrirNuevaCita() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const CitaAddScreen()));
    if (!mounted) return;
    _cargar();
  }

  Future<void> _editarCita(CitaResumen cita) async {
    final edicion = await showModalBottomSheet<_EdicionCita>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => _EditarCitaSheet(cita: cita),
    );
    if (edicion == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );

    try {
      if (edicion.estado != null) {
        await ClienteService.instance.actualizarCitaInfoYEstado(
          cita.id,
          edicion.informacion,
          edicion.estado!,
        );
      } else {
        await ClienteService.instance.actualizarInformacionCita(
          cita.id,
          edicion.informacion,
        );
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita actualizada'),
          backgroundColor: AppColors.mediumGreen,
        ),
      );
      _cargar();
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar la cita: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
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

  Future<void> _abrirDetalle(CitaResumen cita) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: _DetalleCitaSheet(cita: cita),
      ),
    );
  }

  Future<void> _asignarUsuario(CitaResumen cita) async {
    final usuarioId = await showDialog<int>(
      context: context,
      builder: (_) => _AsignarUsuarioDialog(cita: cita),
    );
    if (usuarioId == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );

    try {
      await ClienteService.instance.actualizarUsuarioCita(cita.id, usuarioId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita asignada correctamente'),
          backgroundColor: AppColors.mediumGreen,
        ),
      );
      _cargar();
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar la cita: $error'),
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
          hintText: 'Buscar por contrato, cliente o asignado',
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
        DataColumn(label: Text('Nro Contrato', style: headerStyle)),
        DataColumn(label: Text('Cliente', style: headerStyle)),
        DataColumn(label: Text('Fecha', style: headerStyle)),
        DataColumn(label: Text('Hora', style: headerStyle)),
        DataColumn(label: Text('Información', style: headerStyle)),
        DataColumn(label: Text('Estado', style: headerStyle)),
        DataColumn(label: Text('Asignado a', style: headerStyle)),
        DataColumn(label: Text('Acciones', style: headerStyle)),
      ],
      rows: [
        for (final cita in _items)
          DataRow(
            onSelectChanged: (_) => _abrirDetalle(cita),
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
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    cita.informacion,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                EstadoBadge(
                  estado: cita.estado,
                  onTap: _puedeCambiarEstado
                      ? () => _cambiarEstado(cita)
                      : null,
                ),
              ),
              DataCell(Text(cita.asignadoA)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editarCita(cita),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.darkGreen,
                      ),
                      tooltip: 'Editar información',
                    ),
                    if (_puedeAsignar) ...[
                      IconButton(
                        onPressed: () => _asignarUsuario(cita),
                        icon: const Icon(
                          Icons.assignment_ind_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        tooltip: 'Asignar',
                      ),
                      if (_puedeEliminar)
                        IconButton(
                          onPressed: () => _eliminarCita(cita),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade700,
                          ),
                          tooltip: 'Eliminar',
                        ),
                    ],
                  ],
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

class _AsignarUsuarioDialog extends StatefulWidget {
  const _AsignarUsuarioDialog({required this.cita});

  final CitaResumen cita;

  @override
  State<_AsignarUsuarioDialog> createState() => _AsignarUsuarioDialogState();
}

class _AsignarUsuarioDialogState extends State<_AsignarUsuarioDialog> {
  List<UsuarioResumen> _usuarios = [];
  int? _seleccionado;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _seleccionado = widget.cita.usuarioId;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final usuarios = await ClienteService.instance.fetchUsuariosAsignables();
      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
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
    return AlertDialog(
      title: const Text('Asignar cita'),
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
            'Error al cargar usuarios:\n$_error',
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
    if (_usuarios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No hay usuarios disponibles.'),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _seleccionado,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Asignado a',
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryBlue),
      ),
      items: [
        for (final usuario in _usuarios)
          DropdownMenuItem(
            value: usuario.id,
            child: Text(
              usuario.nombre.isEmpty ? 'Usuario ${usuario.id}' : usuario.nombre,
            ),
          ),
      ],
      onChanged: (value) => setState(() => _seleccionado = value),
    );
  }
}

class _DetalleCitaSheet extends StatelessWidget {
  const _DetalleCitaSheet({required this.cita});

  final CitaResumen cita;

  @override
  Widget build(BuildContext context) {
    final info = cita.informacion.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          cita.contrato.isEmpty ? '(Sin contrato)' : cita.contrato,
          style: const TextStyle(
            color: AppColors.darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _fila('Cliente', cita.cliente),
        _fila('Fecha', cita.fecha),
        _fila('Hora', cita.hora),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'Estado',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: EstadoBadge(estado: cita.estado)),
            ],
          ),
        ),
        _fila('Asignado a', cita.asignadoA),
        const Divider(height: 32),
        Text(
          'Información',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          info.isEmpty ? 'Sin información registrada' : info,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
      ],
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              valor.trim().isEmpty ? '—' : valor,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _EdicionCita {
  const _EdicionCita({this.informacion, this.estado});

  final String? informacion;
  final String? estado;
}

class _EditarCitaSheet extends StatefulWidget {
  const _EditarCitaSheet({required this.cita});

  final CitaResumen cita;

  @override
  State<_EditarCitaSheet> createState() => _EditarCitaSheetState();
}

class _EditarCitaSheetState extends State<_EditarCitaSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.cita.informacion,
  );

  late String _estado = _estadoInicial(widget.cita.estado);

  bool get _puedeCambiarEstado {
    final rol = Sesion.instance.rol;
    return rol == 1 || rol == 5;
  }

  static String _estadoInicial(String estado) {
    final valor = estado.trim().toUpperCase();
    return estadosCita.contains(valor) ? valor : 'PENDIENTE';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _guardar() {
    final texto = _controller.text.trim();
    Navigator.of(context).pop(
      _EdicionCita(
        informacion: texto.isEmpty ? null : texto,
        estado: _puedeCambiarEstado ? _estado : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Editar cita',
            style: TextStyle(
              color: AppColors.darkBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (widget.cita.contrato.isNotEmpty)
                'Contrato: ${widget.cita.contrato}',
              if (widget.cita.cliente.isNotEmpty)
                'Cliente: ${widget.cita.cliente}',
            ].join(' · '),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _estado,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Estado',
              prefixIcon: Icon(
                Icons.flag_outlined,
                color: AppColors.primaryBlue,
              ),
            ),
            items: [
              for (final estado in estadosCita)
                DropdownMenuItem(value: estado, child: Text(estado)),
            ],
            onChanged: _puedeCambiarEstado
                ? (value) {
                    if (value != null) setState(() => _estado = value);
                  }
                : null,
          ),
          if (!_puedeCambiarEstado) ...[
            const SizedBox(height: 6),
            Text(
              'Solo los roles 1 y 5 pueden cambiar el estado.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          Flexible(
            child: TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 3,
              autofocus: true,
              textAlignVertical: TextAlignVertical.top,
              inputFormatters: const [UpperCaseTextFormatter()],
              decoration: InputDecoration(
                labelText: 'Información extra',
                alignLabelWithHint: true,
                prefixIcon: const Icon(
                  Icons.notes_outlined,
                  color: AppColors.primaryBlue,
                ),
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
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
