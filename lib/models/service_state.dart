import 'package:flutter/material.dart';

/// Possible states of a managed service.
enum ServiceStatus {
  stopped,
  running,
  failed,
  starting,
  stopping,
  unknown;

  /// User-facing label for this status.
  String get label {
    switch (this) {
      case ServiceStatus.stopped:
        return 'Stopped';
      case ServiceStatus.running:
        return 'Running';
      case ServiceStatus.failed:
        return 'Failed';
      case ServiceStatus.starting:
        return 'Starting';
      case ServiceStatus.stopping:
        return 'Stopping';
      case ServiceStatus.unknown:
        return 'Unknown';
    }
  }

  /// Colour used to represent this status in the UI.
  Color get color {
    switch (this) {
      case ServiceStatus.stopped:
        return Colors.grey;
      case ServiceStatus.running:
        return Colors.green;
      case ServiceStatus.failed:
        return Colors.red;
      case ServiceStatus.starting:
        return Colors.orange;
      case ServiceStatus.stopping:
        return Colors.orange;
      case ServiceStatus.unknown:
        return Colors.blueGrey;
    }
  }

  /// Icon for this status.
  IconData get icon {
    switch (this) {
      case ServiceStatus.stopped:
        return Icons.stop_circle_outlined;
      case ServiceStatus.running:
        return Icons.check_circle;
      case ServiceStatus.failed:
        return Icons.error;
      case ServiceStatus.starting:
        return Icons.hourglass_top;
      case ServiceStatus.stopping:
        return Icons.hourglass_bottom;
      case ServiceStatus.unknown:
        return Icons.help_outline;
    }
  }
}

/// Runtime state of a single managed service.
class ServiceState {
  final String serviceName;
  final ServiceStatus status;
  final List<String> recentLogs;

  const ServiceState({
    required this.serviceName,
    this.status = ServiceStatus.unknown,
    this.recentLogs = const [],
  });

  ServiceState copyWith({
    ServiceStatus? status,
    List<String>? recentLogs,
  }) {
    return ServiceState(
      serviceName: serviceName,
      status: status ?? this.status,
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }
}
