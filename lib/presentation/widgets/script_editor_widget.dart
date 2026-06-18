import 'package:flutter/material.dart';

class ScriptEditorWidget extends StatelessWidget {
  final String script;
  final ValueChanged<String> onChanged;
  final String label;

  const ScriptEditorWidget({
    super.key,
    required this.script,
    required this.onChanged,
    this.label = 'Script',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: TextEditingController(text: script)
                ..selection = TextSelection.collapsed(offset: script.length),
              onChanged: onChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: '// pm.test("Status is 200", () => {\n//   pm.expect(pm.response.code).to.eql(200);\n// });',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
