import 'service_manager.dart';
import 'mock_service_manager.dart';

/// Creates the appropriate [ServiceManager] for the current platform.
///
/// On web, always returns [MockServiceManager].
/// On non-web platforms, this stub also returns [MockServiceManager],
/// but the real implementation in `service_manager_factory_io.dart`
/// returns [SystemdServiceManager].
ServiceManager createServiceManager() => MockServiceManager();
