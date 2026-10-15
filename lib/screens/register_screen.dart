import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/upper_case_formatter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _codigoAsesorController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  bool _loadingGrupos = true;
  String? _gruposError;
  List<Grupo> _grupos = [];
  int? _selectedGrupo;

  @override
  void initState() {
    super.initState();
    _loadGrupos();
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _codigoAsesorController.dispose();
    _telefonoController.dispose();
    _usuarioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadGrupos() async {
    setState(() {
      _loadingGrupos = true;
      _gruposError = null;
    });
    try {
      final grupos = await AuthService.instance.fetchGrupos();
      if (!mounted) return;
      setState(() {
        _grupos = grupos;
        _loadingGrupos = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingGrupos = false;
        _gruposError = 'No se pudieron cargar los grupos: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_gruposError!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String? _validateText(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Este campo es obligatorio';
    if (trimmed != value) return 'Sin espacios al inicio o final';
    return null;
  }

  String? _validateUsuario(String? value) {
    final base = _validateText(value);
    if (base != null) return base;
    final trimmed = value!.trim();
    if (trimmed.contains(' ')) return 'El usuario no puede contener espacios';
    return null;
  }

  String? _validateNumber(String? value, String label) {
    final base = _validateText(value);
    if (base != null) return base;
    final n = int.tryParse(value!.trim());
    if (n == null || n <= 0) return '$label debe ser un número válido';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final codigoAsesor = int.parse(_codigoAsesorController.text.trim());
      if (await AuthService.instance.codigoAsesorExiste(codigoAsesor)) {
        if (mounted) setState(() => _saving = false);
        _showMessage(
          'El código de asesor ya está registrado para otro usuario',
        );
        return;
      }
      final usuario = _usuarioController.text.trim();
      if (await AuthService.instance.usuarioExiste(usuario)) {
        if (mounted) setState(() => _saving = false);
        _showMessage('El usuario ya está registrado');
        return;
      }

      await AuthService.instance.registrarUsuario(
        nombres: _nombresController.text.trim().toUpperCase(),
        apellidos: _apellidosController.text.trim().toUpperCase(),
        codigoAsesor: codigoAsesor,
        grupo: _selectedGrupo!,
        telefono: int.parse(_telefonoController.text.trim()),
        usuario: usuario,
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await _showSuccessDialog();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Error al registrar: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Registro exitoso',
          style: TextStyle(color: AppColors.darkBlue),
        ),
        content: const Text('Tu usuario fue creado correctamente.'),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check),
            label: const Text('Aceptar'),
          ),
        ],
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
          'Registrar usuario',
          style: TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  elevation: isDesktop ? 8 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: AppColors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 40 : 24,
                      vertical: isDesktop ? 40 : 28,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.person_add_alt_1,
                            size: 44,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Crea tu cuenta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Completa tus datos para registrarte',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _nombresController,
                            inputFormatters: const [UpperCaseTextFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Nombres',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            validator: _validateText,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _apellidosController,
                            inputFormatters: const [UpperCaseTextFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Apellidos',
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            validator: _validateText,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _codigoAsesorController,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [UpperCaseTextFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Código Asesor',
                              prefixIcon: Icon(
                                Icons.numbers,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            validator: (value) =>
                                _validateNumber(value, 'El código de asesor'),
                          ),
                          const SizedBox(height: 16),
                          _buildGrupoField(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _telefonoController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: const [UpperCaseTextFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            validator: (value) =>
                                _validateNumber(value, 'El teléfono'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usuarioController,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            validator: _validateUsuario,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.primaryBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: _validateText,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirmar Contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.primaryBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              final base = _validateText(value);
                              if (base != null) return base;
                              if (value != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _saving ? null : _handleRegister,
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Registrar'),
                          ),
                          if (_saving) const SizedBox(height: 8),
                          if (_saving)
                            const Text(
                              'Guardando...',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrupoField() {
    if (_loadingGrupos) {
      return const TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Grupo',
          prefixIcon: Icon(Icons.groups_outlined, color: AppColors.primaryBlue),
          hintText: 'Cargando grupos...',
        ),
      );
    }
    return DropdownButtonFormField<int>(
      initialValue: _selectedGrupo,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Grupo',
        prefixIcon: Icon(Icons.groups_outlined, color: AppColors.primaryBlue),
      ),
      items: [
        for (final grupo in _grupos)
          DropdownMenuItem(value: grupo.id, child: Text(grupo.nombre)),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGrupo = value;
        });
      },
      validator: (value) => value == null ? 'Selecciona un grupo' : null,
    );
  }
}
