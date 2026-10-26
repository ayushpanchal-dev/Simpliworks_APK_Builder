import 'package:flutter/material.dart';
import '../../services/client_registry_service.dart';
import '../../models/client_model.dart';
import '../../theme/app_theme.dart';
import '../dialogs/client_editor_dialog.dart';
import '../dialogs/module_editor_dialog.dart';

class ClientsModulesView extends StatefulWidget {
  final ClientRegistryService registryService;
  final VoidCallback onDataChanged;

  const ClientsModulesView({
    super.key,
    required this.registryService,
    required this.onDataChanged,
  });

  @override
  State<ClientsModulesView> createState() => _ClientsModulesViewState();
}

class _ClientsModulesViewState extends State<ClientsModulesView> {
  String _searchQuery = '';
  String? _clientFilterId; // null = all clients

  Future<void> _openAddClient() async {
    final result = await showDialog<ClientProfile>(
      context: context,
      builder: (context) => const ClientEditorDialog(),
    );

    if (result != null) {
      await widget.registryService.saveClient(result);
      setState(() {});
      widget.onDataChanged();
    }
  }

  Future<void> _openEditClient(ClientProfile client) async {
    final result = await showDialog<ClientProfile>(
      context: context,
      builder: (context) => ClientEditorDialog(client: client),
    );

    if (result != null) {
      await widget.registryService.saveClient(result);
      setState(() {});
      widget.onDataChanged();
    }
  }

  Future<void> _deleteClient(ClientProfile client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client?'),
        content: Text('Are you sure you want to remove "${client.name}" and its associated modules? This cannot be undone.'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.registryService.deleteClient(client.id);
      setState(() {});
      widget.onDataChanged();
    }
  }

  Future<void> _openAddModule({String? defaultClientId}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ModuleEditorDialog(
        clients: widget.registryService.clients,
        initialClientId: defaultClientId ?? _clientFilterId,
      ),
    );

    if (result != null) {
      final clientId = result['clientId'] as String;
      final module = result['module'] as ClientModuleConfig;
      await widget.registryService.addOrUpdateModuleForClient(clientId, module);
      setState(() {});
      widget.onDataChanged();
    }
  }

  Future<void> _openEditModule(String clientId, ClientModuleConfig module) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ModuleEditorDialog(
        clients: widget.registryService.clients,
        initialClientId: clientId,
        module: module,
      ),
    );

    if (result != null) {
      final updatedClientId = result['clientId'] as String;
      final updatedModule = result['module'] as ClientModuleConfig;
      
      if (updatedClientId != clientId) {
        await widget.registryService.removeModuleFromClient(clientId, module.id);
      }
      await widget.registryService.addOrUpdateModuleForClient(updatedClientId, updatedModule);
      setState(() {});
      widget.onDataChanged();
    }
  }

  Future<void> _deleteModule(String clientId, ClientModuleConfig module) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Module?'),
        content: Text('Remove module "${module.displayName}" from client?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.registryService.removeModuleFromClient(clientId, module.id);
      setState(() {});
      widget.onDataChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allClients = widget.registryService.clients;
    final filteredClients = allClients.where((c) {
      if (_clientFilterId != null && c.id != _clientFilterId) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchClient = c.name.toLowerCase().contains(query) || c.id.toLowerCase().contains(query);
        final matchModule = c.modules.any((m) => m.displayName.toLowerCase().contains(query) || m.id.toLowerCase().contains(query));
        return matchClient || matchModule;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Clients & Modules Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage client Home repositories, environment base URLs, and client-associated feature modules.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.extension_rounded, size: 18, color: AppTheme.primaryIndigo),
                      label: const Text('Add Module'),
                      onPressed: () => _openAddModule(),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Client'),
                      onPressed: _openAddClient,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search & Client Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search clients or modules...',
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _clientFilterId,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Client',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All Clients')),
                          ...allClients.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _clientFilterId = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Client Cards with Associated Modules
            Expanded(
              child: filteredClients.isEmpty
                  ? const Center(child: Text('No clients or modules matched your search.'))
                  : ListView.separated(
                      itemCount: filteredClients.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final client = filteredClients[index];
                        return _buildClientCard(client);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(ClientProfile client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySky.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    client.id,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primarySky, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    client.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppTheme.primaryIndigo),
                  tooltip: 'Add Module for this Client',
                  onPressed: () => _openAddModule(defaultClientId: client.id),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                  tooltip: 'Edit Client',
                  onPressed: () => _openEditClient(client),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
                  tooltip: 'Delete Client',
                  onPressed: () => _deleteClient(client),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Home Repo URL & Branch
            Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    client.homeRepoUrl,
                    style: const TextStyle(fontSize: 12, fontFamily: 'Consolas', color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.fork_right_rounded, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Default: ${client.defaultHomeBranch}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Associated Modules Table
            const Text(
              'Associated Feature Modules:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            if (client.modules.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'No modules associated with this client yet. Click the + button above to register one.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              )
            else
              ...client.modules.map((m) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.extension_rounded, size: 16, color: AppTheme.primaryIndigo),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          m.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          m.repoUrl,
                          style: const TextStyle(fontSize: 11, fontFamily: 'Consolas', color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Text(
                          'branch: ${m.defaultBranch}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (m.isStandaloneSupported)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySky.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Standalone APK',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primarySky),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textSecondary),
                        tooltip: 'Edit Module',
                        onPressed: () => _openEditModule(client.id, m),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorRed),
                        tooltip: 'Remove Module',
                        onPressed: () => _deleteModule(client.id, m),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
