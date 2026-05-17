import 'package:flutter/material.dart';

import '../../core/api/vendor_service.dart';
import '../../core/theme/app_theme.dart';

class BlockedAccountPage extends StatefulWidget {
  const BlockedAccountPage({
    super.key,
    required this.onLogout,
    this.reason,
  });

  final VoidCallback onLogout;
  final String? reason;

  @override
  State<BlockedAccountPage> createState() => _BlockedAccountPageState();
}

class _BlockedAccountPageState extends State<BlockedAccountPage> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _requestUnlock() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await VendorService.requestAccountUnlock(
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Unlock request submitted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Account Blocked'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          TextButton(
            onPressed: widget.onLogout,
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Your account is blocked',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.reason?.trim().isNotEmpty == true
                          ? widget.reason!.trim()
                          : 'Your account is currently blocked by the admin team.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Unlock request note',
                        hintText: 'Write a short note for the admin team',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _requestUnlock,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_open_rounded),
                        label: Text(
                          _isSubmitting ? 'Submitting...' : 'Request Unlock',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.onLogout,
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
