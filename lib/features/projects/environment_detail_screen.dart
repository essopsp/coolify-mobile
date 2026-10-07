import 'package:flutter/material.dart';

import '../../core/models/environment.dart';
import '../../shared/widgets/sections.dart';

class EnvironmentDetailScreen extends StatelessWidget {
  const EnvironmentDetailScreen({super.key, required this.environment});

  final Environment environment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(environment.name ?? 'Environment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text('Details',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                InfoRow('Name', environment.name),
                InfoRow('UUID', environment.uuid),
                InfoRow('Description', environment.description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
