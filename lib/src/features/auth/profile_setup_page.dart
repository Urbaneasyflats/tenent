import 'package:flutter/material.dart';

import '../../core/api/vendor_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({
    super.key,
    required this.onCompleted,
    this.onBack,
  });

  final VoidCallback onCompleted;
  final VoidCallback? onBack;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await VendorService.setVendorProfile(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (response.success) {
        widget.onCompleted();
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            response.message ?? response.status ?? 'Failed to save profile.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
        title: const Text('Complete Profile'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          children: <Widget>[
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: <Color>[
                      AppTheme.primary,
                      AppTheme.primaryHover,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Finish your account setup',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'The website asks for basic profile information after OTP when the account is still incomplete. The mobile app now does the same.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Basic information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Enter a valid full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final RegExp emailPattern = RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        );
                        if (!emailPattern.hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Complete Profile',
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _submitProfile,
                      ),
                    ),
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: 14),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
