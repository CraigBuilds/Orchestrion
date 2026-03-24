import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:orchestrion/main.dart';
import 'package:orchestrion/providers/app_state.dart';
import 'package:orchestrion/screens/home_screen.dart';
import 'package:orchestrion/services/mock_service_manager.dart';

void main() {
  group('HomeScreen', () {
    late MockServiceManager manager;

    setUp(() {
      manager = MockServiceManager();
    });

    tearDown(() {
      manager.dispose();
    });

    Widget createTestApp({
      Future<String?> Function()? onLoadConfig,
      Future<String?> Function()? onPickExportDir,
    }) {
      return MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AppState(manager, enablePolling: false),
          child: HomeScreen(
            onLoadConfig: onLoadConfig,
            onPickExportDir: onPickExportDir,
          ),
        ),
      );
    }

    testWidgets('smoke test: app starts and shows empty state', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Orchestrion'), findsOneWidget);
      expect(find.text('No services configured'), findsOneWidget);
      expect(find.text('Load Config'), findsOneWidget);
    });

    testWidgets('shows services after loading config', (tester) async {
      const yaml = '''
services:
  - name: Test Service
    system: test-system
    service_type: processing
    command: "echo hello"
''';

      await tester.pumpWidget(createTestApp(
        onLoadConfig: () async => yaml,
      ));
      await tester.pumpAndSettle();

      // Tap Load Config button
      await tester.tap(find.text('Load Config'));
      await tester.pumpAndSettle();

      expect(find.text('Test Service'), findsOneWidget);
      expect(find.text('test-system'), findsOneWidget);
    });

    testWidgets('can switch between group modes', (tester) async {
      const yaml = '''
services:
  - name: Svc A
    system: sys1
    service_type: typeA
    command: "echo a"
  - name: Svc B
    system: sys2
    service_type: typeA
    command: "echo b"
''';

      await tester.pumpWidget(createTestApp(
        onLoadConfig: () async => yaml,
      ));
      await tester.pumpAndSettle();

      // Load config
      await tester.tap(find.text('Load Config'));
      await tester.pumpAndSettle();

      // Default is by system, should show system group names
      expect(find.text('sys1'), findsOneWidget);
      expect(find.text('sys2'), findsOneWidget);

      // Switch to by type
      await tester.tap(find.text('By Type'));
      await tester.pumpAndSettle();

      expect(find.text('typeA'), findsOneWidget);
    });

    testWidgets('start all button is available after loading', (tester) async {
      const yaml = '''
services:
  - name: Svc1
    system: sys
    service_type: type
    command: "echo test"
''';

      await tester.pumpWidget(createTestApp(
        onLoadConfig: () async => yaml,
      ));
      await tester.pumpAndSettle();

      // Load config
      await tester.tap(find.text('Load Config'));
      await tester.pumpAndSettle();

      // Start All button should be present
      expect(find.text('Start All'), findsOneWidget);
    });

    testWidgets('export button is disabled with no configs loaded',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final exportButton = find.byWidgetPredicate(
        (w) => w is IconButton && (w.tooltip == 'Export services'),
      );
      expect(exportButton, findsOneWidget);
      // onPressed is null when configs is empty → button is disabled.
      final btn = tester.widget<IconButton>(exportButton);
      expect(btn.onPressed, isNull);
    });

    testWidgets('export button is enabled after loading config', (tester) async {
      const yaml = '''
services:
  - name: Svc1
    system: sys
    service_type: type
    command: "echo test"
''';

      await tester.pumpWidget(createTestApp(
        onLoadConfig: () async => yaml,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Load Config'));
      await tester.pumpAndSettle();

      final exportButton = find.byWidgetPredicate(
        (w) => w is IconButton && (w.tooltip == 'Export services'),
      );
      final btn = tester.widget<IconButton>(exportButton);
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('tapping export button invokes onPickExportDir callback',
        (tester) async {
      const yaml = '''
services:
  - name: Svc1
    system: sys
    service_type: type
    command: "echo test"
''';

      bool pickerCalled = false;

      await tester.pumpWidget(createTestApp(
        onLoadConfig: () async => yaml,
        onPickExportDir: () async {
          pickerCalled = true;
          return '/tmp/test-export';
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Load Config'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is IconButton && w.tooltip == 'Export services',
        ),
      );
      await tester.pumpAndSettle();

      expect(pickerCalled, isTrue);
    });

    testWidgets('OrchestrionApp widget renders', (tester) async {
      await tester.pumpWidget(
        OrchestrionApp(serviceManager: manager),
      );
      await tester.pumpAndSettle();

      expect(find.text('Orchestrion'), findsOneWidget);
    });
  });
}
