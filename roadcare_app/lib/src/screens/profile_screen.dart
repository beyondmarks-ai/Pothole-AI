import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)!;
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          const PageHeader(eyebrow: 'Account & system', title: 'Profile'),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.blue, AppColors.teal],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.role.label,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Workspace'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                const _SettingTile(
                  icon: Icons.apartment_rounded,
                  title: 'Bidar municipal workspace',
                  subtitle: 'Primary jurisdiction',
                ),
                const Divider(height: 1, indent: 68),
                const _SettingTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  subtitle: 'Critical cases and assignments',
                ),
                const Divider(height: 1, indent: 68),
                SwitchListTile(
                  value: dark,
                  onChanged: (value) =>
                      ref.read(themeModeProvider.notifier).toggle(value),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text(
                    'Dark appearance',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Reduce glare during night inspections'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('System'),
          const SizedBox(height: 10),
          const Card(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.psychology_outlined,
                  title: 'AI model',
                  subtitle: 'YOLOv8-Small-RDD2022 · Ready',
                ),
                Divider(height: 1, indent: 68),
                _SettingTile(
                  icon: Icons.cloud_done_outlined,
                  title: 'Cloud synchronization',
                  subtitle: 'Demo repository · Ready for API',
                ),
                Divider(height: 1, indent: 68),
                _SettingTile(
                  icon: Icons.security_outlined,
                  title: 'Privacy and audit',
                  subtitle: 'Role controls and evidence history',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'RoadCare AI · Prototype 1.0.0',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () {},
  );
}
