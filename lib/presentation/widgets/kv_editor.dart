import 'package:flutter/material.dart';

class KvEntry {
  String key;
  String value;
  bool enabled;

  KvEntry({this.key = '', this.value = '', this.enabled = true});
}

class KvEditor extends StatelessWidget {
  final List<KvEntry> entries;
  final ValueChanged<List<KvEntry>> onChanged;
  final String addButtonLabel;

  const KvEditor({
    super.key,
    required this.entries,
    required this.onChanged,
    this.addButtonLabel = 'Add',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...entries.asMap().entries.map((e) => _buildRow(e.key, e.value)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            final updated = List<KvEntry>.from(entries)..add(KvEntry());
            onChanged(updated);
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text(addButtonLabel),
        ),
      ],
    );
  }

  Widget _buildRow(int index, KvEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Checkbox(
              value: entry.enabled,
              onChanged: (v) {
                final updated = List<KvEntry>.from(entries);
                updated[index] = KvEntry(
                  key: entry.key,
                  value: entry.value,
                  enabled: v ?? true,
                );
                onChanged(updated);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: TextEditingController(text: entry.key)
                ..selection = TextSelection.collapsed(offset: entry.key.length),
              onChanged: (v) {
                final updated = List<KvEntry>.from(entries);
                updated[index] = KvEntry(
                  key: v,
                  value: entry.value,
                  enabled: entry.enabled,
                );
                onChanged(updated);
              },
              decoration: const InputDecoration(
                hintText: 'Key',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: TextEditingController(text: entry.value)
                ..selection = TextSelection.collapsed(offset: entry.value.length),
              onChanged: (v) {
                final updated = List<KvEntry>.from(entries);
                updated[index] = KvEntry(
                  key: entry.key,
                  value: v,
                  enabled: entry.enabled,
                );
                onChanged(updated);
              },
              decoration: const InputDecoration(
                hintText: 'Value',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {
              final updated = List<KvEntry>.from(entries)..removeAt(index);
              onChanged(updated);
            },
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
