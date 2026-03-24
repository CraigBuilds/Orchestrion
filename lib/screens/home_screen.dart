import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/app_state.dart';
import '../services/config_loader.dart';
import '../widgets/service_group_view.dart';
import 'log_screen.dart';

/// The main home screen showing all services grouped and with controls.
class HomeScreen extends StatelessWidget {
  /// Optional callback for loading config (used in tests to inject config).
  final Future<String?> Function()? onLoadConfig;

  const HomeScreen({super.key, this.onLoadConfig});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Orchestrion'),
            actions: [
              // Group mode toggle
              SegmentedButton<GroupMode>(
                segments: const [
                  ButtonSegment(
                    value: GroupMode.bySystem,
                    label: Text('By System'),
                    icon: Icon(Icons.computer),
                  ),
                  ButtonSegment(
                    value: GroupMode.byServiceType,
                    label: Text('By Type'),
                    icon: Icon(Icons.category),
                  ),
                ],
                selected: {appState.groupMode},
                onSelectionChanged: (selected) {
                  appState.setGroupMode(selected.first);
                },
              ),
              const SizedBox(width: 16),
              // Start All button
              FilledButton.icon(
                onPressed: appState.configs.isEmpty
                    ? null
                    : () => appState.startAll(),
                icon: const Icon(Icons.play_circle),
                label: const Text('Start All'),
              ),
              const SizedBox(width: 8),
              // Load config button
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: 'Load config',
                onPressed: () => _loadConfig(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: appState.configs.isEmpty
              ? _buildEmptyState(context)
              : _buildServiceList(context, appState),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_suggest, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No services configured',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Load a YAML config file to get started.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _loadConfig(context),
            icon: const Icon(Icons.folder_open),
            label: const Text('Load Config'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList(BuildContext context, AppState appState) {
    final groups = appState.groupedConfigs;

    return Column(
      children: [
        if (appState.error != null)
          MaterialBanner(
            content: Text(appState.error!),
            backgroundColor: Colors.red[50],
            actions: [
              TextButton(
                onPressed: () {}, // Error clears on next action
                child: const Text('DISMISS'),
              ),
            ],
          ),
        Expanded(
          child: ListView(
            children: groups.entries.map((entry) {
              return ServiceGroupView(
                groupName: entry.key,
                services: entry.value,
                onViewLogs: (name) => _openLogScreen(context, name),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _openLogScreen(BuildContext context, String serviceName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: Provider.of<AppState>(context, listen: false),
          child: LogScreen(serviceName: serviceName),
        ),
      ),
    );
  }

  Future<void> _loadConfig(BuildContext context) async {
    try {
      String? content;
      if (onLoadConfig != null) {
        content = await onLoadConfig!();
      } else {
        content = await _pickAndReadConfig();
      }
      if (content == null) return;
      final configs = ConfigLoader.parseYaml(content);
      if (context.mounted) {
        await Provider.of<AppState>(context, listen: false)
            .loadConfigs(configs);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load config: $e')),
        );
      }
    }
  }

  Future<String?> _pickAndReadConfig() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      return String.fromCharCodes(result.files.single.bytes!);
    }
    return null;
  }
}
