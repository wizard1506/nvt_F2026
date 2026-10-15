import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'agenda_screen.dart';
import 'citas_screen.dart';
import 'cosolicitantes_screen.dart';
import 'formularios_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Novitierra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.darkBlue),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1000;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1000;
          final columns = isDesktop ? 3 : (isTablet ? 2 : 1);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : 24,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menú principal',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: AppColors.darkBlue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona una opción para continuar',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: isDesktop ? 1.4 : (isTablet ? 1.3 : 1.5),
                  children: [
                    _buildMenuCard(
                      context,
                      title: 'Formularios',
                      subtitle: 'Gestiona los formularios',
                      icon: Icons.description_outlined,
                      color: AppColors.primaryBlue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FormulariosScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Prospectos',
                      subtitle: 'Administra tus prospectos',
                      icon: Icons.people_outline,
                      color: AppColors.mediumGreen,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Prospectos - Próximamente'),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Co-Solicitantes',
                      subtitle: 'Gestiona co-solicitantes',
                      icon: Icons.group_add_outlined,
                      color: AppColors.primaryBlue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CosolicitantesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Citas',
                      subtitle: 'Gestiona tus citas',
                      icon: Icons.event_available_outlined,
                      color: AppColors.darkGreen,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CitasScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Agenda',
                      subtitle: 'Calendario de citas',
                      icon: Icons.calendar_month_outlined,
                      color: AppColors.lightBlue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AgendaScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
