import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/features/auth/data/auth_repository.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _isResending = false;
  bool _isChecking = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
    // Auto-check periodically
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerificationStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final isVerified = await ref.read(authRepositoryProvider).isEmailVerified();
      if (mounted) {
        setState(() => _isChecking = false);
        if (isVerified) {
          _timer?.cancel();
          // Routing logic will naturally take over once verification changes
          // but we can force a router refresh just in case
          context.go('/onboarding');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isChecking = false);
      debugPrint('Status check error: $e');
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email resent!'), backgroundColor: Color(0xFF027B3D)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.mail, size: 72, color: Color(0xFF027B3D)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D3B2E),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We\'ve sent a verification link to your email address. Please click the link to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              if (_isChecking)
                const Center(child: CircularProgressIndicator(color: Color(0xFF027B3D)))
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _checkVerificationStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF027B3D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('I\'ve Verified My Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isResending ? null : _resendEmail,
                      child: _isResending
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Resend Email', style: TextStyle(color: Color(0xFF027B3D), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
