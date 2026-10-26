import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class TerminalConsole extends StatefulWidget {
  final Stream<String> logStream;
  final String status;
  final VoidCallback? onClear;

  const TerminalConsole({
    super.key,
    required this.logStream,
    this.status = 'Ready',
    this.onClear,
  });

  @override
  State<TerminalConsole> createState() => _TerminalConsoleState();
}

class _TerminalConsoleState extends State<TerminalConsole> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    widget.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
        });
        if (_autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
    widget.onClear?.call();
  }

  void _copyLogs() {
    Clipboard.setData(ClipboardData(text: _logs.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Console logs copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.textPrimary,
      ),
    );
  }

  Color _getLineColor(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('error') || lower.contains('fatal') || lower.contains('failed')) {
      return AppTheme.consoleRed;
    }
    if (lower.contains('warning') || lower.contains('warn')) {
      return AppTheme.consoleAmber;
    }
    if (lower.contains('success') || lower.contains('completed') || lower.contains('done')) {
      return AppTheme.consoleGreen;
    }
    if (line.startsWith('[') || line.startsWith('>>>') || line.startsWith('===')) {
      return AppTheme.consoleSky;
    }
    return AppTheme.consoleText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.consoleBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Console Header Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B), // Slate 800
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, size: 18, color: AppTheme.consoleSky),
                const SizedBox(width: 8),
                const Text(
                  'Execution Console',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.status == 'Building'
                        ? AppTheme.primarySky.withValues(alpha: 0.2)
                        : (widget.status == 'Success'
                            ? AppTheme.successGreen.withValues(alpha: 0.2)
                            : Colors.white10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.status == 'Building'
                          ? AppTheme.consoleSky
                          : (widget.status == 'Success'
                              ? AppTheme.consoleGreen
                              : Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Auto-scroll toggle
                IconButton(
                  tooltip: _autoScroll ? 'Disable Auto-scroll' : 'Enable Auto-scroll',
                  icon: Icon(
                    _autoScroll ? Icons.arrow_downward : Icons.vertical_align_bottom,
                    size: 16,
                    color: _autoScroll ? AppTheme.consoleSky : Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      _autoScroll = !_autoScroll;
                    });
                  },
                ),
                // Copy button
                IconButton(
                  tooltip: 'Copy Logs',
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                  onPressed: _logs.isEmpty ? null : _copyLogs,
                ),
                // Clear button
                IconButton(
                  tooltip: 'Clear Console',
                  icon: const Icon(Icons.clear_all_rounded, size: 18, color: Colors.white70),
                  onPressed: _logs.isEmpty ? null : _clearLogs,
                ),
              ],
            ),
          ),

          // Log Lines Area
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      'Ready to build. Console output will stream here in real-time.',
                      style: TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final line = _logs[index];
                      return Text(
                        line,
                        style: TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 12,
                          height: 1.45,
                          color: _getLineColor(line),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
