import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serverIpController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _privateKeyPathController = TextEditingController();

  String? _privateKeyPath;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    _usernameController.dispose();
    _passphraseController.dispose();
    _privateKeyPathController.dispose();
    super.dispose();
  }

  _loadSettings() async {
    _serverIpController.text = await storage.read(key: "serverIp") ?? 'defaultServerIp';
    _usernameController.text = await storage.read(key: "username") ?? 'defaultUsername';
    _passphraseController.text = await storage.read(key: "passphrase") ?? '';
    _privateKeyPath = await storage.read(key: "privateKeyPath");
    _privateKeyPathController.text = _privateKeyPath ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _serverIpController,
              decoration: const InputDecoration(labelText: 'Server IP'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the Server IP';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the username';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _passphraseController,
              decoration: const InputDecoration(labelText: 'Passphrase (optional)'),
            ),
            TextFormField(
              controller: _privateKeyPathController,
              decoration: const InputDecoration(labelText: 'Private Key Path (optional)'),
              readOnly: true,
              onTap: _browsePrivateKey,
              validator: (value) {
                // Perform validation if needed
                return null;
              },
            ),
            ElevatedButton(
              child: const Text('Browse Private Key'),
              onPressed: _browsePrivateKey,
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: _saveSettings,
            ),
          ],
        ),
      ),
    );
  }

  void _browsePrivateKey() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      _privateKeyPath = result.files.first.path;
      _privateKeyPathController.text = _privateKeyPath ?? '';
    }
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      await storage.write(key: "serverIp", value: _serverIpController.text);
      await storage.write(key: "username", value: _usernameController.text);
      await storage.write(key: "passphrase", value: _passphraseController.text);
      await storage.write(key: "privateKeyPath", value: _privateKeyPath ?? '');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Settings Saved!'),
      ));
    }
  }
}
