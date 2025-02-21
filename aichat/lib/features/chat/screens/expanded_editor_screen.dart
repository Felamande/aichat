import 'package:flutter/material.dart';
import '../../../l10n/translations.dart';

class ExpandedEditorScreen extends StatefulWidget {
  final String initialText;
  final Function(String) onTextChanged;

  const ExpandedEditorScreen({
    super.key,
    required this.initialText,
    required this.onTextChanged,
  });

  @override
  State<ExpandedEditorScreen> createState() => _ExpandedEditorScreenState();
}

class _ExpandedEditorScreenState extends State<ExpandedEditorScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('expanded_editor')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onTextChanged(_controller.text);
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: l10n.get('type_message'),
          ),
          onChanged: widget.onTextChanged,
        ),
      ),
    );
  }
}
