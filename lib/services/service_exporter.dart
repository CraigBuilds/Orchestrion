import 'dart:io';

import '../models/service_config.dart';

/// Generates and exports systemd service unit files.
///
/// Separates service-definition generation from the service lifecycle
/// managed by [ServiceManager], so unit files can be inspected, version
/// controlled, or used independently of Orchestrion.
class ServiceExporter {
  /// Generate the systemd unit file content for a [ServiceConfig].
  ///
  /// Returns a self-contained `.service` file that can be installed into any
  /// standard systemd location and used without Orchestrion at runtime.
  static String generateUnitContent(ServiceConfig config) {
    return '[Unit]\n'
        'Description=Orchestrion: ${config.name}\n'
        '\n'
        '[Service]\n'
        'Type=simple\n'
        'ExecStart=${config.effectiveCommand}\n'
        'Restart=no\n'
        '\n'
        '[Install]\n'
        'WantedBy=default.target\n';
  }

  /// Export systemd unit files for all [configs] to [outputDir].
  ///
  /// Creates [outputDir] if it does not already exist.
  /// Writes one `.service` file per config using each config's [unitName].
  static Future<void> exportServices(
    List<ServiceConfig> configs,
    String outputDir,
  ) async {
    final dir = Directory(outputDir);
    await dir.create(recursive: true);
    for (final config in configs) {
      final content = generateUnitContent(config);
      final file = File('$outputDir/${config.unitName}');
      await file.writeAsString(content);
    }
  }
}
