import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../config/supabase_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rawPhone = _phoneController.text.trim();
      // Remove any non-digit characters from the input
      final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
      
      // Combine with fixed Brazil code for now (or make dynamic later)
      final phone = '+55$cleanPhone';
      
      // DEV BYPASS: If phone is the placeholder/test number, skip Supabase
      if (cleanPhone == '11999999999') {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Modo de Teste: Código 123456')),
          );
          context.push('/verify-otp', extra: phone);
        }
        return;
      }

      // Dummy OTP for testing since we don't have SMS setup yet
      // In production, Supabase would send an SMS
      await SupabaseConfig.client.auth.signInWithOtp(
        phone: phone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código enviado! (Verifique o console do Supabase)')),
        );
        if (mounted) {
          context.push('/verify-otp', extra: phone);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocorreu um erro inesperado'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / Branding
              Text(
                'FIDELIO',
                style: theme.textTheme.displayLarge?.copyWith(color: theme.primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sua carteira de benefícios premium',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Phone Input Row
              Container(
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  children: [
                    // Country Code Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.2))),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: '+55',
                          dropdownColor: theme.cardColor,
                          items: const [
                            DropdownMenuItem(value: '+55', child: Text('🇧🇷 +55')),
                            DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                          ],
                          onChanged: (value) {
                            // TODO: Handle country change if needed
                          },
                        ),
                      ),
                    ),
                    
                    // Phone Number Field
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: '11 99999-9999',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Button
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('ENTRAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
