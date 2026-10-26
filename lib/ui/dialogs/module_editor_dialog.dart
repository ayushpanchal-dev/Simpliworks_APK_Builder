import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../theme/app_theme.dart';

class ModuleEditorDialog extends StatefulWidget {
  final List<ClientProfile> clients;
  final String? initialClientId;
  final ClientModuleConfig? module;

  const ModuleEditorDialog({
    super.key,
    required this.clients,
    this.initialClientId,
    this.module,
  });

  @override
  State<ModuleEditorDialog> createState() => _ModuleEditorDialogState();
}

class _ModuleEditorDialogState extends State<ModuleEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedClientId;
  late TextEditingController _idController;
  late TextEditingController _displayNameController;
  late TextEditingController _repoUrlController;
  late TextEditingController _branchController;
  bool _isStandaloneSupported = true;
  bool _isRequiredInHome = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.initialClientId ?? (widget.clients.isNotEmpty ? widget.clients.first.id : null);
    final m = widget.module;
    _idController = TextEditingController(text: m?.id ?? '');
    _displayNameController = TextEditingController(text: m?.displayName ?? '');
    _repoUrlController = TextEditingController(text: m?.repoUrl ?? '');
    _branchController = TextEditingController(text: m?.defaultBranch ?? 'master');
    _isStandaloneSupported = m?.isStandaloneSupported ?? true;
    _isRequiredInHome = m?.isRequiredInHome ?? false;
  }

  @override
  void dispose() {
    _idController.dispose();
    _displayNameController.dispose();
    _repoUrlController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null || _selectedClientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Every module must be associated with a client.')),
      );
      return;
    }

    final updated = ClientModuleConfig(
      id: _idController.text.trim(),
      displayName: _displayNameController.text.trim(),
      repoUrl: _repoUrlController.text.trim(),
      defaultBranch: _branchController.text.trim(),
      isStandaloneSupported: _isStandaloneSupported,
      isRequiredInHome: _isRequiredInHome,
    );

    Navigator.of(context).pop({
      'clientId': _selectedClientId,
      'module': updated,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.module != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
                          color: AppTheme.primaryIndigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.extension_rounded, color: AppTheme.primaryIndigo, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Client Module' : 'Register Module for Client',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Modules must belong to a client and can support standalone APK builds.',
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

                  // Required Client Selection
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClientId,
                    decoration: const InputDecoration(
                      labelText: 'Associated Client (Required)',
                      prefixIcon: Icon(Icons.business_rounded, size: 18, color: AppTheme.primarySky),
                    ),
                    items: widget.clients.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text('${c.name} (${c.id})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedClientId = val;
                      });
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Client selection is mandatory' : null,
                  ),
                  const SizedBox(height: 16),

                  // Identifier & Display Name
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _idController,
                          enabled: !isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Module Package ID',
                            hintText: 'e.g. deliver_module',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            hintText: 'e.g. Deliver Module',
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
                      labelText: 'Module Git Repository URL',
                      hintText: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-BRM_Deliver_GUI.git',
                      prefixIcon: Icon(Icons.link_rounded, size: 20, color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Git URL is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Default Branch
                  TextFormField(
                    controller: _branchController,
                    decoration: const InputDecoration(
                      labelText: 'Default Branch',
                      hintText: 'master',
                      prefixIcon: Icon(Icons.fork_right_rounded, size: 20, color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Default branch is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Checkboxes
                  CheckboxListTile(
                    title: const Text(
                      'Supports Standalone APK Build',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    subtitle: const Text(
                      'If enabled, this module can be built independently without Home.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    value: _isStandaloneSupported,
                    activeColor: AppTheme.primarySky,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setState(() {
                        _isStandaloneSupported = val ?? true;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Always Required in Home Composite',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    subtitle: const Text(
                      'If enabled, this module is pre-selected whenever Home is built.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    value: _isRequiredInHome,
                    activeColor: AppTheme.primaryIndigo,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setState(() {
                        _isRequiredInHome = val ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Actions
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
                        label: Text(isEditing ? 'Save Changes' : 'Register Module'),
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
