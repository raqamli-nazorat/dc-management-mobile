import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../features/auth/model/auth_notifier.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    final state = ref.read(authNotifierProvider);
    if (state is AuthError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Stack(
        children: [
          // Gold gradient top accent
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 300,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [Color(0x10C9A96E), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.graphite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gold.withAlpha(80)),
                      ),
                      child: const Center(
                        child: Text(
                          'DC',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('DC Management', style: AppTextStyles.h1),
                    const SizedBox(height: 6),
                    const Text('Boshqaruv paneliga kiring', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 40),

                    // Card
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.smoke),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Tizimga kirish', style: AppTextStyles.h2),
                            const SizedBox(height: 24),

                            // Email field
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: AppColors.ivory),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'admin@dcmanagement.uz',
                                prefixIcon: Icon(Icons.email_outlined, size: 18),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email kiriting';
                                if (!v.contains('@')) return 'Email noto\'g\'ri';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              style: const TextStyle(color: AppColors.ivory),
                              decoration: InputDecoration(
                                labelText: 'Parol',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: AppColors.silver,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 6) return 'Kamida 6 ta belgi';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Login button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(AppColors.obsidian),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login, size: 18),
                                          SizedBox(width: 8),
                                          Text('Kirish'),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'DC Management System © ${DateTime.now().year}',
                      style: const TextStyle(color: AppColors.ash, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
