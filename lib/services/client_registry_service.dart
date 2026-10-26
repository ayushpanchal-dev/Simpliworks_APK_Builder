import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client_model.dart';

class ClientRegistryService {
  static const String _clientsPrefKey = 'simpliworks_clients_registry_v4';

  final List<ClientProfile> _clients = [];

  List<ClientProfile> get clients => List.unmodifiable(_clients);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    final clientsJsonStr = prefs.getString(_clientsPrefKey);
    if (clientsJsonStr != null && clientsJsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(clientsJsonStr);
        _clients.clear();
        for (var item in decoded) {
          _clients.add(ClientProfile.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (e) {
        _seedDefaultClients();
      }
    } else {
      _seedDefaultClients();
      await _persistClients();
    }
  }

  void _seedDefaultClients() {
    _clients.clear();
    _clients.addAll([
      const ClientProfile(
        id: 'BRM',
        name: 'BRM (Shree BRM Oil Mills)',
        homeRepoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-BRM_Main_GUI.git',
        defaultHomeBranch: 'master',
        baseUrls: {
          'production': 'https://brmdemo2.simpliworks.co.in/',
          'testing': 'https://wscsw2.simpliworks.co.in:453/',
          'preprod': 'https://preprod-brmdemo2.simpliworks.co.in/',
        },
        modules: [
          ClientModuleConfig(
            id: 'deliver_module',
            displayName: 'Deliver Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-BRM_Deliver_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
          ClientModuleConfig(
            id: 'crm_module',
            displayName: 'CRM Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-BRM_CRM_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
          ClientModuleConfig(
            id: 'expense_module',
            displayName: 'Expense Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-BRM_Expense_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
          ClientModuleConfig(
            id: 'finance_module',
            displayName: 'Finance Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-BRM_Finance_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
        ],
      ),
      const ClientProfile(
        id: 'Kalika',
        name: 'Kalika Steels',
        homeRepoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-Kalika_Home_GUI.git',
        defaultHomeBranch: 'master',
        baseUrls: {
          'production': 'https://kalikademo.simpliworks.co.in/',
          'testing': 'https://wscsw2.simpliworks.co.in:453/',
          'preprod': 'https://preprod-kalika.simpliworks.co.in/',
        },
        modules: [
          ClientModuleConfig(
            id: 'deliver_module',
            displayName: 'Deliver Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-Kalika_Deliver_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
          ClientModuleConfig(
            id: 'crm_module',
            displayName: 'CRM Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-Kalika_CRM_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
          ClientModuleConfig(
            id: 'expense_module',
            displayName: 'Expense Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-Kalika_Expense_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
          ClientModuleConfig(
            id: 'finance_module',
            displayName: 'Finance Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-Kalika_Finance_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
        ],
      ),
      const ClientProfile(
        id: 'Ganraj',
        name: 'Ganraj Enterprises',
        homeRepoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-Ganraj_Home_GUI.git',
        defaultHomeBranch: 'master',
        baseUrls: {
          'production': 'https://ganraj.simpliworks.co.in/',
          'testing': 'https://wscsw2-ganraj.simpliworks.co.in/',
          'preprod': 'https://preprod-ganraj.simpliworks.co.in/',
        },
        modules: [
          ClientModuleConfig(
            id: 'deliver_module',
            displayName: 'Deliver Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-Ganraj_Deliver_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
          ClientModuleConfig(
            id: 'crm_module',
            displayName: 'CRM Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-Ganraj_CRM_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
          ClientModuleConfig(
            id: 'finance_module',
            displayName: 'Finance Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-Ganraj_Finance_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
        ],
      ),
      const ClientProfile(
        id: 'Vasudha',
        name: 'Vasudha Chem',
        homeRepoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-VSD_Home_GUI.git',
        defaultHomeBranch: 'master',
        baseUrls: {
          'production': 'https://vasudha.simpliworks.co.in/',
          'testing': 'https://wscsw2.simpliworks.co.in:453/',
          'preprod': 'https://preprod-vasudha.simpliworks.co.in/',
        },
        modules: [
          ClientModuleConfig(
            id: 'deliver_module',
            displayName: 'Deliver Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-VSD_Deliver_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
          ClientModuleConfig(
            id: 'finance_module',
            displayName: 'Finance Module',
            repoUrl: 'http://vitplgit.vegainnovations.co.in/WSC-SW-2.0-VSD_Finance_GUI.git',
            defaultBranch: 'master',
            isStandaloneSupported: true,
          ),
        ],
      ),
    ]);
  }

  Future<void> saveClient(ClientProfile client) async {
    final index = _clients.indexWhere((c) => c.id == client.id);
    if (index >= 0) {
      _clients[index] = client;
    } else {
      _clients.add(client);
    }
    await _persistClients();
  }

  Future<void> deleteClient(String clientId) async {
    _clients.removeWhere((c) => c.id == clientId);
    await _persistClients();
  }

  Future<void> addOrUpdateModuleForClient(String clientId, ClientModuleConfig module) async {
    final clientIndex = _clients.indexWhere((c) => c.id == clientId);
    if (clientIndex < 0) return;

    final client = _clients[clientIndex];
    final updatedModules = List<ClientModuleConfig>.from(client.modules);
    final modIndex = updatedModules.indexWhere((m) => m.id == module.id);

    if (modIndex >= 0) {
      updatedModules[modIndex] = module;
    } else {
      updatedModules.add(module);
    }

    _clients[clientIndex] = client.copyWith(modules: updatedModules);
    await _persistClients();
  }

  Future<void> removeModuleFromClient(String clientId, String moduleId) async {
    final clientIndex = _clients.indexWhere((c) => c.id == clientId);
    if (clientIndex < 0) return;

    final client = _clients[clientIndex];
    final updatedModules = client.modules.where((m) => m.id != moduleId).toList();

    _clients[clientIndex] = client.copyWith(modules: updatedModules);
    await _persistClients();
  }

  Future<void> _persistClients() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _clients.map((c) => c.toJson()).toList();
    await prefs.setString(_clientsPrefKey, jsonEncode(jsonList));
  }
}
