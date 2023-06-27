import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ssh_king/settings_page.dart';
import 'command.dart';
import 'add_command_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class CommandListPage extends StatefulWidget {
  const CommandListPage({Key? key}) : super(key: key);

  @override
  CommandListPageState createState() => CommandListPageState();
}

class CommandListPageState extends State<CommandListPage> {
  final ValueNotifier<int> _commandsNotifier = ValueNotifier<int>(0);
  final storage = const FlutterSecureStorage();

  Future<List<Command>> fetchCommands() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Fetch the list of commands. If it doesn't exist, returns an empty list.
    List<String>? commandsJson = prefs.getStringList('commands');

    // Parse the stored JSON strings into Command objects
    List<Command> commands = commandsJson != null
        ? commandsJson.map((json) => Command.fromJson(json)).toList()
        : [];

    return commands;
  }

  void _openSettingsPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );

    // Perform any necessary actions with the result from the settings page
    if (result != null) {
      // Handle the result
    }
  }


  void executeCommand(String command) async {
    // Obtain shared preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the required information from shared preferences
    final String? host = await storage.read(key: "serverIp");
    final String? username = await storage.read(key: "username");
    final String? password = await storage.read(key: "passphrase");
    final String? keyFilePath = await storage.read(key: "privateKeyPath");

    if (host == null || username == null) {
      throw Exception('Host and username must be provided in shared preferences');
    }

    // Define a function that will provide the password if it's given
    String? passwordProvider() {
      if (password != null) {
        return password;
      } else {
        return null;
      }
    }

    // If keyFilePath is given, try to read the SSH keys from it
    List<SSHKeyPair>? identities;
    if (keyFilePath != null) {
      final keyText = await File(keyFilePath).readAsString();
      identities = SSHKeyPair.fromPem(keyText);
    }

    // Connect to the SSH server and execute the command
    final client = SSHClient(
      await SSHSocket.connect(host, 22),
      username: username,
      onPasswordRequest: passwordProvider,
      identities: identities,
    );

    final result = await client.run(command);
    print(utf8.decode(result));

    client.close();
  }

  Future<void> deleteCommand(Command command) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Fetch the current list of commands
    List<String>? commandsJson = prefs.getStringList('commands');

    // Parse the stored JSON strings into Command objects
    List<Command> commands = commandsJson != null
        ? commandsJson.map((json) => Command.fromJson(json)).toList()
        : [];

    // Remove the command from the list
    commands.remove(command);

    // Convert the list of Command objects to JSON strings
    List<String> updatedCommandsJson =
    commands.map((command) => command.toJson()).toList();

    // Save the updated list of commands
    await prefs.setStringList('commands', updatedCommandsJson);

    // Notify the UI to refresh the list of commands
    _commandsNotifier.value++;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commands'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _openSettingsPage();
            },
          ),
        ],

      ),
      body: ValueListenableBuilder<int>(
        valueListenable: _commandsNotifier,
        builder: (context, value, child) {
          return FutureBuilder<List<Command>>(
            future: fetchCommands(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final command = snapshot.data![index];
                      return Dismissible(
                          key: Key(command.name), // Use the command name as the unique key for the Dismissible
                          onDismissed: (direction) {
                            deleteCommand(command);
                          },
                      child: ListTile(
                        title: Text(command.name),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Execute command?'),
                                content: Text('Do you want to execute the command: ${command.command}?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Execute'),
                                    onPressed: () {
                                      executeCommand(command.command);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      )
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: Text('No commands found'),
                  );
                }
              } else {
                return const CircularProgressIndicator();
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          // Navigate to AddCommandPage and await the result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCommandPage()),
          );

          // If a new command was added, refresh the list of commands
          if (result != null && result == true) {
            _commandsNotifier.value++;
          }
        },
      ),
    );
  }
}
