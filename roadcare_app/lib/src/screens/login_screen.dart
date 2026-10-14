import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController(text: 'citizen@roadcare.app');
  final password = TextEditingController(text: 'roadcare');
  UserRole role = UserRole.citizen;
  bool obscure = true;

  String _demoEmail(UserRole value) => switch (value) {
    UserRole.citizen => 'citizen@roadcare.app',
    UserRole.officer || UserRole.administrator => 'officer@bidar.gov.in',
    UserRole.maintenance => 'team@roadcare.gov.in',
  };

  String get _emailLabel => switch (role) {
    UserRole.citizen => 'Email address',
    UserRole.officer || UserRole.administrator => 'Municipal work email',
    UserRole.maintenance => 'Team work email',
  };

  String get _dashboardLabel => switch (role) {
    UserRole.citizen => 'Open citizen dashboard',
    UserRole.officer || UserRole.administrator => 'Open municipal dashboard',
    UserRole.maintenance => 'Open repair team dashboard',
  };

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.blue, AppColors.teal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: .25),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'RoadCare AI',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Safer roads. Accountable repairs.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 34),
                Text(
                  'Choose your role',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Each role has a separate, focused dashboard.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                SegmentedButton<UserRole>(
                  direction: Axis.vertical,
                  segments: const [
                    ButtonSegment(
                      value: UserRole.citizen,
                      icon: Icon(Icons.person_outline_rounded),
                      label: Text('Citizen'),
                    ),
                    ButtonSegment(
                      value: UserRole.officer,
                      icon: Icon(Icons.account_balance_outlined),
                      label: Text('Municipal officer'),
                    ),
                    ButtonSegment(
                      value: UserRole.maintenance,
                      icon: Icon(Icons.engineering_outlined),
                      label: Text('Assigned repair team'),
                    ),
                  ],
                  selected: {role},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    final value = selection.first;
                    setState(() {
                      role = value;
                      email.text = _demoEmail(value);
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: _emailLabel,
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(sessionProvider.notifier)
                      .signIn(email.text, role),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(_dashboardLabel),
                ),
                const SizedBox(height: 16),
                const Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    Text(
                      'Demo mode - use the pre-filled details',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
