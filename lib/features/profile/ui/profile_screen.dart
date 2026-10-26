import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/platform_file_ext.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorHandler.toUserMessage(error)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (!file.isReadable) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .uploadAvatar(await file.toMultipart());
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).deleteAvatar();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAvatarSheet(bool hasAvatar) {
    return showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Choose picture'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar();
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove picture'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editUsername(String current) async {
    final controller = TextEditingController(text: current);
    final formKey = GlobalKey<FormState>();

    final newUsername = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit username'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 50,
            decoration: const InputDecoration(labelText: 'Username'),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.length < 3) return 'At least 3 characters';
              if (v.length > 50) return 'At most 50 characters';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newUsername == null || newUsername == current) return;

    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).updateUsername(newUsername);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Profile')),
      body: GlowBackground(
        child: user == null
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : AbsorbPointer(
                absorbing: _busy,
                child: Opacity(
                  opacity: _busy ? 0.6 : 1,
                  child: SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          children: [
                            Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: AppColors.aiGradient(
                                          Theme.of(context).brightness,
                                        ),
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: cs.surface,
                                      ),
                                      child: UserAvatar(user: user, radius: 52),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Tooltip(
                                      message: 'Change picture',
                                      child: Material(
                                        color: cs.primary,
                                        shape: CircleBorder(
                                          side: BorderSide(
                                            color: cs.surface,
                                            width: 3,
                                          ),
                                        ),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: () =>
                                              _openAvatarSheet(user.hasAvatar),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.photo_camera_outlined,
                                              size: 18,
                                              color: cs.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 6,
                                ),
                                child: Column(
                                  children: [
                                    _InfoTile(
                                      label: 'Username',
                                      value: user.username,
                                      onEdit: () =>
                                          _editUsername(user.username),
                                    ),
                                    const Divider(),
                                    _InfoTile(
                                      label: 'Email',
                                      value: user.email,
                                    ),
                                    const Divider(),
                                    _InfoTile(
                                      label: 'User ID',
                                      value: '#${user.id}',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              child: ListTile(
                                leading: Icon(
                                  Icons.logout_rounded,
                                  color: cs.error,
                                ),
                                title: Text(
                                  'Log out',
                                  style: TextStyle(color: cs.error),
                                ),
                                onTap: () =>
                                    ref.read(authProvider.notifier).logout(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, this.onEdit});

  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Label above value, so long values (emails) get the full width.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit $label',
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
