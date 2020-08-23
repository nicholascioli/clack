import 'package:flutter/material.dart';

class StringSetFragment extends StatefulWidget {
  final String label;
  final String initialValue;

  StringSetFragment({@required this.label, this.initialValue = ""});

  @override
  _StringSetFragmentState createState() => _StringSetFragmentState();
}

class _StringSetFragmentState extends State<StringSetFragment> {
  TextEditingController _controller;

  @override
  void initState() {
    // Set the controller with initial value
    _controller = TextEditingController(text: widget.initialValue);

    super.initState();
  }

  @override
  void dispose() {
    // Trash the controller
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      content: new Row(
        children: <Widget>[
          new Expanded(
            child: new TextField(
              controller: _controller,
              autofocus: true,
              decoration: new InputDecoration(labelText: widget.label),
              maxLines: null,
            ),
          )
        ],
      ),
      actions: <Widget>[
        new FlatButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context, "");
            }),
        new FlatButton(
            child: const Text('Save'),
            onPressed: () {
              Navigator.pop(context, _controller.value.text);
            }),
      ],
    );
  }
}
