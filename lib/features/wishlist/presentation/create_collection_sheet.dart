import 'package:flutter/material.dart';

class CreateCollectionSheet extends StatefulWidget {
  final ValueChanged<String> onCreate;

  const CreateCollectionSheet({super.key, required this.onCreate});

  @override
  State<CreateCollectionSheet> createState() => _CreateCollectionSheetState();
}

class _CreateCollectionSheetState extends State<CreateCollectionSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Collection name'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onCreate(_controller.text);
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }
}
