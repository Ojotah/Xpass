import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/account.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/vault_providers.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({
    super.key,
    this.index,
    this.initialAccount,
  });

  final int? index;
  final Account? initialAccount;

  bool get isEdit => index != null && initialAccount != null;

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  bool _isSaving = false;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  double _length = 16;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialAccount?.title ?? '');
    _usernameController =
        TextEditingController(text: widget.initialAccount?.username ?? '');
    _passwordController =
        TextEditingController(text: widget.initialAccount?.password ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final account = Account(
      title: _titleController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    final controller = ref.read(vaultControllerProvider.notifier);
    if (widget.isEdit) {
      await controller.updateAccountAt(widget.index!, account);
    } else {
      await controller.addAccount(account);
    }

    if (!mounted) return;

    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  void _generatePassword() {
    final generated = ref.read(generatePasswordUseCaseProvider).call(
          length: _length.round(),
          includeUppercase: _includeUppercase,
          includeLowercase: _includeLowercase,
          includeNumbers: _includeNumbers,
          includeSymbols: _includeSymbols,
        );
    _passwordController.text = generated;
  }

  Future<void> _copyPassword() async {
    await ref.read(copyToClipboardUseCaseProvider).call(
          _passwordController.text,
          autoClear: (ref.read(settingsControllerProvider).valueOrNull ?? AppSettings.defaults)
              .clipboardClearEnabled,
          clearAfter: Duration(
            seconds: (ref.read(settingsControllerProvider).valueOrNull ?? AppSettings.defaults)
                .clipboardClearDuration,
          ),
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? 'Edit Account' : 'Add Account';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _generatePassword,
                        icon: const Icon(Icons.password),
                        label: const Text('Generate'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _passwordController.text.isEmpty ? null : _copyPassword,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Generator settings',
                              style: Theme.of(context).textTheme.titleMedium),
                          Slider(
                            min: 8,
                            max: 32,
                            divisions: 24,
                            value: _length,
                            label: _length.round().toString(),
                            onChanged: (value) => setState(() => _length = value),
                          ),
                          Text('Length: ${_length.round()}'),
                          SwitchListTile(
                            value: _includeUppercase,
                            title: const Text('Uppercase'),
                            onChanged: (value) => setState(() => _includeUppercase = value),
                          ),
                          SwitchListTile(
                            value: _includeLowercase,
                            title: const Text('Lowercase'),
                            onChanged: (value) => setState(() => _includeLowercase = value),
                          ),
                          SwitchListTile(
                            value: _includeNumbers,
                            title: const Text('Numbers'),
                            onChanged: (value) => setState(() => _includeNumbers = value),
                          ),
                          SwitchListTile(
                            value: _includeSymbols,
                            title: const Text('Symbols'),
                            onChanged: (value) => setState(() => _includeSymbols = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
