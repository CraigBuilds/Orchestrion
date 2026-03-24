import 'service_manager.dart';
import 'systemd_service_manager.dart';

/// Creates the appropriate [ServiceManager] for non-web platforms.
ServiceManager createServiceManager() => SystemdServiceManager();
