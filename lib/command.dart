import 'dart:convert';

class Command {
  final String name;
  final String command;

  Command(this.name, this.command);

  factory Command.fromJson(String json) {
    final Map<String, dynamic> data = jsonDecode(json);
    return Command(data['name'], data['command']);
  }

  String toJson() {
    final Map<String, dynamic> data = {'name': name, 'command': command};
    return jsonEncode(data);
  }
}
