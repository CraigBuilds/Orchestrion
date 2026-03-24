import 'package:flutter/material.dart';

import '../models/service_config.dart';
import 'service_card.dart';

/// Displays a group of services under a named heading.
class ServiceGroupView extends StatelessWidget {
  final String groupName;
  final List<ServiceConfig> services;
  final void Function(String serviceName)? onViewLogs;

  const ServiceGroupView({
    super.key,
    required this.groupName,
    required this.services,
    this.onViewLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            groupName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((config) {
              return SizedBox(
                width: 320,
                child: ServiceCard(
                  serviceName: config.name,
                  onTapLogs: onViewLogs != null
                      ? () => onViewLogs!(config.name)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
