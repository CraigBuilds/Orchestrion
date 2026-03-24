import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:orchestrion/models/service_config.dart';
import 'package:orchestrion/services/service_exporter.dart';

void main() {
  group('ServiceExporter', () {
    final commandConfig = ServiceConfig.fromMap({
      'name': 'Camera Driver',
      'system': 'perception',
      'service_type': 'sensor',
      'command': '/usr/bin/camera_driver --config /etc/camera.yaml',
    });

    final rosConfig = ServiceConfig.fromMap({
      'name': 'Lidar',
      'system': 'perception',
      'service_type': 'sensor',
      'ros': {'package': 'lidar_pkg', 'executable': 'lidar_node'},
    });

    group('generateUnitContent', () {
      test('contains correct [Unit] section', () {
        final content = ServiceExporter.generateUnitContent(commandConfig);
        expect(content, contains('[Unit]'));
        expect(content, contains('Description=Orchestrion: Camera Driver'));
      });

      test('contains correct [Service] section', () {
        final content = ServiceExporter.generateUnitContent(commandConfig);
        expect(content, contains('[Service]'));
        expect(content, contains('Type=simple'));
        expect(
          content,
          contains(
            'ExecStart=/usr/bin/camera_driver --config /etc/camera.yaml',
          ),
        );
        expect(content, contains('Restart=no'));
      });

      test('contains correct [Install] section', () {
        final content = ServiceExporter.generateUnitContent(commandConfig);
        expect(content, contains('[Install]'));
        expect(content, contains('WantedBy=default.target'));
      });

      test('uses effectiveCommand for ROS config', () {
        final content = ServiceExporter.generateUnitContent(rosConfig);
        expect(content, contains('ExecStart=ros2 run lidar_pkg lidar_node'));
      });

      test('content is deterministic', () {
        final a = ServiceExporter.generateUnitContent(commandConfig);
        final b = ServiceExporter.generateUnitContent(commandConfig);
        expect(a, equals(b));
      });

      test('content ends with a newline', () {
        final content = ServiceExporter.generateUnitContent(commandConfig);
        expect(content.endsWith('\n'), isTrue);
      });
    });

    group('exportServices', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('orchestrion_test_');
      });

      tearDown(() async {
        await tempDir.delete(recursive: true);
      });

      test('creates the output directory if it does not exist', () async {
        final subDir = '${tempDir.path}/nested/output';
        await ServiceExporter.exportServices([commandConfig], subDir);
        expect(Directory(subDir).existsSync(), isTrue);
      });

      test('writes one .service file per config', () async {
        await ServiceExporter.exportServices(
          [commandConfig, rosConfig],
          tempDir.path,
        );

        expect(
          File('${tempDir.path}/${commandConfig.unitName}').existsSync(),
          isTrue,
        );
        expect(
          File('${tempDir.path}/${rosConfig.unitName}').existsSync(),
          isTrue,
        );
      });

      test('written file content matches generateUnitContent', () async {
        await ServiceExporter.exportServices([commandConfig], tempDir.path);

        final written = await File(
          '${tempDir.path}/${commandConfig.unitName}',
        ).readAsString();
        expect(
          written,
          equals(ServiceExporter.generateUnitContent(commandConfig)),
        );
      });

      test('exported files are self-contained systemd unit files', () async {
        await ServiceExporter.exportServices([commandConfig], tempDir.path);

        final content = await File(
          '${tempDir.path}/${commandConfig.unitName}',
        ).readAsString();
        // Must have all three sections for a valid standalone unit file.
        expect(content, contains('[Unit]'));
        expect(content, contains('[Service]'));
        expect(content, contains('[Install]'));
        // ExecStart must reference the full command.
        expect(
          content,
          contains(
            'ExecStart=/usr/bin/camera_driver --config /etc/camera.yaml',
          ),
        );
      });

      test('does not write extra files', () async {
        await ServiceExporter.exportServices([commandConfig], tempDir.path);

        final files = tempDir
            .listSync()
            .whereType<File>()
            .map((f) => f.path.split('/').last)
            .toList();
        expect(files, equals([commandConfig.unitName]));
      });

      test('exports are deterministic across multiple calls', () async {
        final dirA = '${tempDir.path}/a';
        final dirB = '${tempDir.path}/b';

        await ServiceExporter.exportServices([commandConfig], dirA);
        await ServiceExporter.exportServices([commandConfig], dirB);

        final contentA =
            await File('$dirA/${commandConfig.unitName}').readAsString();
        final contentB =
            await File('$dirB/${commandConfig.unitName}').readAsString();
        expect(contentA, equals(contentB));
      });

      test('exports empty list without error', () async {
        await ServiceExporter.exportServices([], tempDir.path);
        // No files written, no errors thrown.
        expect(tempDir.listSync(), isEmpty);
      });
    });
  });
}
