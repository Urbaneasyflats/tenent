import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';

import '../../core/api/upload_service.dart';
import '../../core/api/vendor_service.dart';
import '../../core/models/api_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';
import '../legal/legal_policy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  VendorData? _vendor;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVendor();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadVendor() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final VendorData? vendor = await VendorService.fetchVendorInfo();
      if (!mounted) {
        return;
      }

      _vendor = vendor;
      _nameController.text = vendor?.fullName ?? '';
      _emailController.text = vendor?.email ?? '';

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    final String fullName = _nameController.text.trim();
    final String email = _emailController.text.trim();

    if (fullName.isEmpty || email.isEmpty) {
      _showMessage('Name and email are required.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await VendorService.setVendorProfile(
        fullName: fullName,
        email: email,
      );

      if (!mounted) {
        return;
      }

      if (!response.success) {
        _showMessage(response.message ?? 'Unable to update profile.');
      } else {
        _showMessage(response.message ?? 'Profile updated successfully.');
        await _loadVendor();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _uploadPhoto() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) {
      return;
    }

    final String extension =
        result.files.single.extension?.toLowerCase() ?? '';
    if (extension == 'avif') {
      _showMessage('AVIF images are not supported. Please choose JPG or PNG.');
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final String? imageId = await UploadService.uploadImage(
        File(result.files.single.path!),
      );
      if (!mounted) {
        return;
      }

      if (imageId == null) {
        _showMessage('Failed to upload image. Please try again.');
        return;
      }

      final String fullName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (_vendor?.fullName ?? '');
      final String email = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : (_vendor?.email ?? '');

      final response = await VendorService.setVendorProfile(
        fullName: fullName,
        email: email,
        imageId: imageId,
      );
      if (!mounted) {
        return;
      }

      if (!response.success) {
        _showMessage(response.message ?? 'Unable to update profile photo.');
      } else {
        _showMessage('Profile photo updated.');
        await _loadVendor();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _removePhoto() async {
    FocusScope.of(context).unfocus();

    final String fullName = _nameController.text.trim();
    final String email = _emailController.text.trim();
    if (fullName.isEmpty || email.isEmpty) {
      _showMessage('Name and email are required.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String? imageId = _vendor?.imageId;
      if (imageId != null && imageId.isNotEmpty) {
        await UploadService.removeImage(imageId);
      }
      if (!mounted) {
        return;
      }

      final response = await VendorService.setVendorProfile(
        fullName: fullName,
        email: email,
      );

      if (!mounted) {
        return;
      }

      if (!response.success) {
        _showMessage(response.message ?? 'Unable to remove profile photo.');
      } else {
        _showMessage('Profile photo removed.');
        await _loadVendor();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openPolicy(LegalPolicyType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalPolicyPage(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Settings'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVendor,
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(
              title: 'Profile Settings',
              description:
                  'Manage the same profile fields the website settings screen currently exposes.',
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Unable to load profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'Retry',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _loadVendor,
                    ),
                  ],
                ),
              )
            else ...<Widget>[
              CustomCard(
                child: Row(
                  children: <Widget>[
                    _ProfileAvatar(imageUrl: _vendor?.imageUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _vendor?.fullName.isNotEmpty == true
                                ? _vendor!.fullName
                                : 'UrbanEasyFlats user',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _vendor?.phone.isNotEmpty == true
                                ? _vendor!.phone
                                : 'Phone number unavailable',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              ToneBadge(
                                label: _roleLabel(_vendor?.vendorType),
                                tone: UiTone.brand,
                              ),
                              if (_vendor?.vendorId.isNotEmpty == true)
                                ToneBadge(
                                  label: 'Vendor ${_vendor!.vendorId}',
                                  tone: UiTone.neutral,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Profile Photo',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _vendor?.imageUrl?.isNotEmpty == true
                          ? 'A profile photo is set for this account.'
                          : 'No profile photo is set for this account.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: _vendor?.imageUrl?.isNotEmpty == true
                            ? 'Change Photo'
                            : 'Upload Photo',
                        icon: const Icon(Icons.photo_camera_outlined),
                        isLoading: _isUploadingPhoto,
                        onPressed: (_isSaving || _isUploadingPhoto)
                            ? null
                            : _uploadPhoto,
                      ),
                    ),
                    if (_vendor?.imageUrl?.isNotEmpty == true) ...<Widget>[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: 'Remove Current Photo',
                          icon: const Icon(Icons.delete_outline_rounded),
                          variant: CustomButtonVariant.outline,
                          isLoading: _isSaving,
                          onPressed: (_isSaving || _isUploadingPhoto)
                              ? null
                              : _removePhoto,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Profile',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: false,
                      controller: TextEditingController(
                        text: _vendor?.phone ?? '',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Save Profile',
                        icon: const Icon(Icons.save_outlined),
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _saveProfile,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _LegalSettingsCard(onOpenPolicy: _openPolicy),
              const SizedBox(height: 16),
              _AccountDeletionCard(onShowMessage: _showMessage),
            ],
          ],
        ),
      ),
    );
  }

  String _roleLabel(int? vendorType) {
    return switch (vendorType) {
      1 => 'Society',
      2 => 'Property',
      3 => 'Tenant',
      _ => 'Account',
    };
  }
}

class _LegalSettingsCard extends StatelessWidget {
  const _LegalSettingsCard({required this.onOpenPolicy});

  final ValueChanged<LegalPolicyType> onOpenPolicy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Legal',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Read the latest app terms and privacy details.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _LegalRow(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => onOpenPolicy(LegalPolicyType.terms),
          ),
          const Divider(height: 1, color: AppTheme.border),
          _LegalRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => onOpenPolicy(LegalPolicyType.privacy),
          ),
        ],
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String? trimmed = imageUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.primarySoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          color: AppTheme.primary,
          size: 32,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        trimmed,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
          );
        },
      ),
    );
  }
}

class _AccountDeletionCard extends StatefulWidget {
  const _AccountDeletionCard({required this.onShowMessage});

  final void Function(String message) onShowMessage;

  @override
  State<_AccountDeletionCard> createState() => _AccountDeletionCardState();
}

class _AccountDeletionCardState extends State<_AccountDeletionCard> {
  bool _submitted = false;

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This submits a request only.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _submitted = true);
              widget.onShowMessage('Your request has been submitted.');
            },
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Account Deletion',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You can request account deletion from here. This action submits a request only.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              CustomButton(
                label: 'Delete My Account',
                icon: const Icon(Icons.delete_forever_outlined),
                variant: CustomButtonVariant.outline,
                onPressed: _submitted ? null : _confirmDelete,
              ),
              if (_submitted) ...<Widget>[
                const SizedBox(width: 12),
                Text(
                  'Request submitted',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
