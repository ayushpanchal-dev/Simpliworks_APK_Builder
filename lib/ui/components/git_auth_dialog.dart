import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GitAuthDialog extends StatefulWidget {
  final String repoUrl;
  final String? initialUsername;

  const GitAuthDialog({
    super.key,
    required this.repoUrl,
    this.initialUsername,
  });

  @override
  State<GitAuthDialog> createState() => _GitAuthDialogState();
}

class _GitAuthDialogState extends State<GitAuthDialog> {
  late TextEditingController _userController;
  late TextEditingController _tokenController;
  bool _obscureSecret = true;
  bool _rememberCreds = true;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(text: widget.initialUsername ?? '');
    _tokenController = TextEditingController();
  }

  @override
  void dispose() {
    _userController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySky.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_outline, color: AppTheme.primarySky, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Git Authentication Required',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text(
                          'Provide credentials to pull remote repository',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: AppTheme.primarySky),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.repoUrl,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Username / Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _userController,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                decoration: const InputDecoration(hintText: 'e.g. username'),
              ),
              const SizedBox(height: 14),
              const Text('Personal Access Token / Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _tokenController,
                obscureText: _obscureSecret,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Token / Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureSecret ? Icons.visibility_off : Icons.visibility, size: 18, color: AppTheme.textMuted),
                    onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _rememberCreds,
                    activeColor: AppTheme.primarySky,
                    onChanged: (val) => setState(() => _rememberCreds = val ?? true),
                  ),
                  const Text('Remember for this domain in secure storage', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarySky,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final u = _userController.text.trim();
                      final p = _tokenController.text.trim();
                      if (u.isNotEmpty && p.isNotEmpty) {
                        Navigator.of(context).pop({'username': u, 'password': p, 'save': _rememberCreds});
                      }
                    },
                    child: const Text('Authenticate & Continue'),
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
