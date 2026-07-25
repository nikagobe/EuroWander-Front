import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    final theme = Theme.of(context);

    return AppScaffold(
      maxWidth: 400,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                ),
                borderRadius: AppRadius.borderXl,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPrimary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'EuroWander',
              style: theme.textTheme.displayMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Welcome back! Sign in to continue',
              style: theme.textTheme.bodyMedium?.copyWith(color: ew.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            // Email field
            _buildTextField(
              controller: _emailController,
              hint: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            // Password field
            _buildTextField(
              controller: _passwordController,
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ew.textSecondary,
                  size: 20,
                ),
              ),
            ),
            // Error message
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: AppRadius.borderMd,
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            // Login button
            GestureDetector(
              onTap: _isLoading ? null : _login,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                  ),
                  borderRadius: AppRadius.borderLg,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Register link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ew.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: Text(
                    'Sign Up',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    final ew = context.ew;

    return Container(
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: AppRadius.borderLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: GoogleFonts.poppins(fontSize: 14, color: ew.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: ew.textSecondary),
          prefixIcon: Icon(icon, color: ew.textSecondary, size: 20),
          suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: suffix) : null,
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: ew.cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}
