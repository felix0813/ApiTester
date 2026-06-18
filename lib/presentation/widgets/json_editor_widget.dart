import 'package:flutter/material.dart';
import '../../core/utils/json_formatter.dart';

class JsonEditorWidget extends StatelessWidget {
  final String content;
  final ValueChanged<String> onChanged;
  final bool readOnly;

  const JsonEditorWidget({
    super.key,
    required this.content,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!readOnly)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => onChanged(JsonFormatter.prettyPrint(content)),
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Format', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              TextButton.icon(
                onPressed: () => onChanged(JsonFormatter.minify(content)),
                icon: const Icon(Icons.compress, size: 16),
                label: const Text('Minify', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              readOnly: readOnly,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              controller: TextEditingController(text: content)
                ..selection =
                    TextSelection.collapsed(offset: content.length),
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFD4D4D4),
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
        ),
        if (!readOnly)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              JsonFormatter.isValid(content)
                  ? '✓ Valid JSON'
                  : '✗ Invalid JSON',
              style: TextStyle(
                fontSize: 11,
                color: JsonFormatter.isValid(content)
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}
