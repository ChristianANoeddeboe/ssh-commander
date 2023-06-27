import 'package:flutter/material.dart';
import 'command.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCommandPage extends StatefulWidget {
  const AddCommandPage({Key? key}) : super(key: key);

  @override
  AddCommandPageState createState() => AddCommandPageState();
}

class AddCommandPageState extends State<AddCommandPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _command = '';

  void saveCommand(Command command) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Fetch the current list of commands
    List<String>? commandsJson = prefs.getStringList('commands');

    // Parse the stored JSON strings into Command objects
    List<Command> commands = commandsJson != null
        ? commandsJson.map((json) => Command.fromJson(json)).toList()
        : [];

    // Add the new command to the list
    commands.add(command);

    // Convert the list of Command objects to JSON strings
    List<String> updatedCommandsJson =
    commands.map((command) => command.toJson()).toList();

    // Save the updated list of commands
    await prefs.setStringList('commands', updatedCommandsJson);

    // Return true to indicate that a new command was added
    Navigator.pop(context, true);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Command'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name'),
              onSaved: (value) => _name = value!,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Command'),
              onSaved: (value) => _command = value!,
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                // Validate and save command
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Command newCommand = Command(_name, _command);
                  saveCommand(newCommand);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
