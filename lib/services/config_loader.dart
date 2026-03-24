import 'package:yaml/yaml.dart';

import '../models/service_config.dart';

/// Loads service configurations from YAML content.
class ConfigLoader {
  /// Parse a YAML string into a list of [ServiceConfig].
  static List<ServiceConfig> parseYaml(String yamlContent) {
    final doc = loadYaml(yamlContent);
    if (doc is! Map) {
      throw FormatException('Config must be a YAML map with a "services" key.');
    }
    final services = doc['services'];
    if (services is! List) {
      throw FormatException('"services" must be a list.');
    }
    return services.map((entry) {
      if (entry is! Map) {
        throw FormatException('Each service entry must be a map.');
      }
      return ServiceConfig.fromMap(Map<String, dynamic>.from(entry));
    }).toList();
  }
}
