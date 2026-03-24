/// Configuration for a single managed service, loaded from YAML config.
class ServiceConfig {
  final String name;
  final String system;
  final String serviceType;
  final bool startAll;

  /// Generic command to launch the service.
  final String? command;

  /// ROS shorthand fields.
  final String? rosPackage;
  final String? rosExecutable;
  final String? rosArgs;

  ServiceConfig({
    required this.name,
    required this.system,
    required this.serviceType,
    this.startAll = true,
    this.command,
    this.rosPackage,
    this.rosExecutable,
    this.rosArgs,
  }) {
    if (command == null && rosPackage == null) {
      throw ArgumentError(
        'ServiceConfig "$name" must have either a command or ros package/executable.',
      );
    }
  }

  /// Returns the effective command to run this service.
  String get effectiveCommand {
    if (command != null) return command!;
    final args = rosArgs != null ? ' $rosArgs' : '';
    return 'ros2 run $rosPackage $rosExecutable$args';
  }

  /// The systemd unit name derived from the service name.
  String get unitName =>
      'orchestrion-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}.service';

  factory ServiceConfig.fromMap(Map<String, dynamic> map) {
    final ros = map['ros'] as Map<String, dynamic>?;
    return ServiceConfig(
      name: map['name'] as String,
      system: map['system'] as String,
      serviceType: map['service_type'] as String,
      startAll: map['start_all'] as bool? ?? true,
      command: map['command'] as String?,
      rosPackage: ros?['package'] as String?,
      rosExecutable: ros?['executable'] as String?,
      rosArgs: ros?['args'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'system': system,
      'service_type': serviceType,
      'start_all': startAll,
    };
    if (command != null) {
      map['command'] = command;
    }
    if (rosPackage != null) {
      map['ros'] = <String, dynamic>{
        'package': rosPackage,
        'executable': rosExecutable,
        if (rosArgs != null) 'args': rosArgs,
      };
    }
    return map;
  }
}
