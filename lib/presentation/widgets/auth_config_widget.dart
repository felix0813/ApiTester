import 'package:flutter/material.dart';
import '../../data/models/auth_config.dart';

class AuthConfigWidget extends StatelessWidget {
  final AuthConfig config;
  final ValueChanged<AuthConfig> onChanged;

  const AuthConfigWidget({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<AuthType>(
            segments: const [
              ButtonSegment(value: AuthType.none, label: Text('None')),
              ButtonSegment(value: AuthType.bearer, label: Text('Bearer')),
              ButtonSegment(value: AuthType.basic, label: Text('Basic')),
              ButtonSegment(value: AuthType.apiKey, label: Text('API Key')),
            ],
            selected: {config.type},
            onSelectionChanged: (type) {
              onChanged(config.copyWith(type: type.first));
            },
          ),
          const SizedBox(height: 16),

          if (config.type == AuthType.bearer)
            TextField(
              controller: TextEditingController(text: config.token)
                ..selection = TextSelection.collapsed(offset: config.token.length),
              onChanged: (v) => onChanged(config.copyWith(token: v)),
              decoration: const InputDecoration(
                labelText: 'Token',
                hintText: 'eyJhbGci...',
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),

          if (config.type == AuthType.basic) ...[
            TextField(
              controller: TextEditingController(text: config.username)
                ..selection = TextSelection.collapsed(offset: config.username.length),
              onChanged: (v) => onChanged(config.copyWith(username: v)),
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: config.password)
                ..selection = TextSelection.collapsed(offset: config.password.length),
              onChanged: (v) => onChanged(config.copyWith(password: v)),
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],

          if (config.type == AuthType.apiKey) ...[
            TextField(
              controller: TextEditingController(text: config.apiKeyHeader)
                ..selection = TextSelection.collapsed(offset: config.apiKeyHeader.length),
              onChanged: (v) => onChanged(config.copyWith(apiKeyHeader: v)),
              decoration: const InputDecoration(
                labelText: 'Header Name',
                hintText: 'X-API-Key',
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: config.apiKey)
                ..selection = TextSelection.collapsed(offset: config.apiKey.length),
              onChanged: (v) => onChanged(config.copyWith(apiKey: v)),
              decoration: const InputDecoration(labelText: 'API Key'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
