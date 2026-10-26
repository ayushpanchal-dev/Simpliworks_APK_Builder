import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../theme/app_theme.dart';

class ClientEditorDialog extends StatefulWidget {
  final ClientProfile? client;

  const ClientEditorDialog({super.key, this.client});

  @override
  State<ClientEditorDialog> createState() => _ClientEditorDialogState();
}

class _ClientEditorDialogState extends State<ClientEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _repoUrlController;
  late TextEditingController _branchController;
  late TextEditingController _prodUrlController;
  late TextEditingController _testingUrlController;
  late TextEditingController _preprodUrlController;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _idController = TextEditingController(text: c?.id ?? '');
    _nameController = TextEditingController(text: c?.name ?? '');
    _repoUrlController = TextEditingController(text: c?.homeRepoUrl ?? '');
    _branchController = TextEditingController(text: c?.defaultHomeBranch ?? 'main');
    _prodUrlController = TextEditingController(text: c?.baseUrls['production'] ?? c?.baseUrls['Production'] ?? '');
    _testingUrlController = TextEditingController(text: c?.baseUrls['testing'] ?? c?.baseUrls['Testing'] ?? '');
    _preprodUrlController = TextEditingController(text: c?.baseUrls['preprod'] ?? c?.baseUrls['Preprod'] ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _repoUrlController.dispose();
    _branchController.dispose();
    _prodUrlController.dispose();
    _testingUrlController.dispose();
    _preprodUrlController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = ClientProfile(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      homeRepoUrl: _repoUrlController.text.trim(),
      defaultHomeBranch: _branchController.text.trim(),
      baseUrls: {
        'production': _prodUrlController.text.trim(),
        'testing': _testingUrlController.text.trim(),
        'preprod': _preprodUrlController.text.trim(),
      },
      modules: widget.client?.modules ?? [],
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySky.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.business_rounded, color: AppTheme.primarySky, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Client Profile' : 'Add New Client Profile',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Configure remote repository URL and environment base URLs.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Client ID & Name
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _idController,
                          enabled: !isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Client Identifier (ID)',
                            hintText: 'e.g. BRM',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            hintText: 'e.g. BRM (Shree BRM Oil Mills)',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Git Repo URL
                  TextFormField(
                    controller: _repoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Home Git Repository URL',
                      hintText: 'https://gitlab.simpliworks.co.in/projects/client_home.git',
                      prefixIcon: Icon(Icons.link_rounded, size: 20, color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Git URL is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Default Branch
                  TextFormField(
                    controller: _branchController,
                    decoration: const InputDecoration(
                      labelText: 'Default Home Branch',
                      hintText: 'main or master',
                      prefixIcon: Icon(Icons.fork_right_rounded, size: 20, color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Default branch is required' : null,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Environment Base URLs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Testing URL
                  TextFormField(
                    controller: _testingUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Testing (WSC) Base URL',
                      hintText: 'https://wscsw2.simpliworks.co.in:453/',
                      prefixIcon: Icon(Icons.science_rounded, size: 18, color: AppTheme.primarySky),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Preprod URL
                  TextFormField(
                    controller: _preprodUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Preprod Base URL',
                      hintText: 'https://preprod-client.simpliworks.co.in/',
                      prefixIcon: Icon(Icons.flag_rounded, size: 18, color: AppTheme.warningAmber),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Production URL
                  TextFormField(
                    controller: _prodUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Production Base URL',
                      hintText: 'https://clientdemo.simpliworks.co.in/',
                      prefixIcon: Icon(Icons.verified_rounded, size: 18, color: AppTheme.successGreen),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: Text(isEditing ? 'Save Changes' : 'Create Client'),
                        onPressed: _save,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
