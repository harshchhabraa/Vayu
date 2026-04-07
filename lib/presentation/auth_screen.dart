import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vayu/providers/auth/auth_provider.dart';
import 'package:vayu/presentation/widgets/vayu_background.dart';
import 'package:vayu/presentation/widgets/vayu_card.dart';
import 'package:vayu/presentation/widgets/vayu_button.dart';
import 'package:vayu/presentation/widgets/vayu_text_field.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLoginMode) {
      ref.read(authControllerProvider.notifier).signIn(email, password);
    } else {
      ref.read(authControllerProvider.notifier).signUp(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth errors to show a snackbar
    ref.listen<AsyncValue<void>>(
      authControllerProvider,
      (_, state) {
        if (!state.isLoading && state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${state.error}', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: VayuBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.air,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to Vayu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Breathe smarter, live better',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 64),

              VayuCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        _isLoginMode ? 'Login to your account' : 'Create a new account',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00695C),
                        ),
                      ),
                      const SizedBox(height: 24),
                      VayuTextField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter your email';
                          // Basic email regex
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      VayuTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter a password';
                          if (val.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      if (isLoading)
                        const CircularProgressIndicator(color: Color(0xFF00695C))
                      else ...[
                        VayuButton(
                          label: _isLoginMode ? 'Log In' : 'Sign Up',
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _toggleMode,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _isLoginMode 
                                  ? "Don't have an account? Sign up" 
                                  : "Already have an account? Log in",
                              style: const TextStyle(
                                color: Color(0xFF00796B),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
