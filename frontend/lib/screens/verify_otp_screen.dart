import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class VerifyOTPScreen extends StatefulWidget {
  final String phone;

  const VerifyOTPScreen({super.key, required this.phone});

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = _otpController.text.trim();
      
      // DEV BYPASS: Verify test code
      if (token == '123456' && widget.phone.endsWith('11999999999')) {
         if (mounted) {
           context.go('/dashboard');
         }
         return;
      }

      final response = await SupabaseConfig.client.auth.verifyOTP(
        type: OtpType.sms,
        token: token,
        phone: widget.phone,
      );

      if (response.session != null) {
         if (mounted) {
           context.go('/dashboard');
         }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código inválido'), backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verificar Código',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviamos um SMS para ${widget.phone}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '000000',
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading ? const CircularProgressIndicator() : const Text('CONFIRMAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
