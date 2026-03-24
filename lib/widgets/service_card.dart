import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/service_state.dart';
import '../providers/app_state.dart';

/// A compact card displaying a service's status and controls.
class ServiceCard extends StatelessWidget {
  final String serviceName;
  final VoidCallback? onTapLogs;

  const ServiceCard({
    super.key,
    required this.serviceName,
    this.onTapLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final state = appState.stateFor(serviceName);
        final status = state.status;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row: status icon + name + controls
                Row(
                  children: [
                    Icon(status.icon, color: status.color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        serviceName,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 8),
                // Recent logs preview
                if (state.recentLogs.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    constraints: const BoxConstraints(maxHeight: 60),
                    child: Text(
                      state.recentLogs.take(3).join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.greenAccent,
                      ),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                const SizedBox(height: 8),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionButton(
                      icon: Icons.play_arrow,
                      tooltip: 'Start',
                      onPressed: status != ServiceStatus.running
                          ? () => appState.startService(serviceName)
                          : null,
                    ),
                    _ActionButton(
                      icon: Icons.stop,
                      tooltip: 'Stop',
                      onPressed: status == ServiceStatus.running
                          ? () => appState.stopService(serviceName)
                          : null,
                    ),
                    _ActionButton(
                      icon: Icons.refresh,
                      tooltip: 'Restart',
                      onPressed: () => appState.restartService(serviceName),
                    ),
                    if (onTapLogs != null)
                      _ActionButton(
                        icon: Icons.article,
                        tooltip: 'View Logs',
                        onPressed: onTapLogs,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ServiceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: status.color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
