import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/section_header.dart';
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
  late final TextEditingController _noteController;

  bool _isSaving = false;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  double _length = 16;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialAccount?.title ?? '');
    _usernameController =
        TextEditingController(text: widget.initialAccount?.username ?? '');
    _passwordController =
        TextEditingController(text: widget.initialAccount?.password ?? '');
    _noteController =
        TextEditingController(text: widget.initialAccount?.note ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _noteController.dispose();
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
      note: _noteController.text.trim(),
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
    setState(() {});
  }

  Future<void> _copyPassword() async {
    await ref.read(copyToClipboardUseCaseProvider).call(
          _passwordController.text,
          autoClear: (ref.read(settingsControllerProvider).valueOrNull ??
                  AppSettings.defaults)
              .clipboardClearEnabled,
          clearAfter: Duration(
            seconds: (ref.read(settingsControllerProvider).valueOrNull ??
                    AppSettings.defaults)
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
    final title = widget.isEdit ? 'Edit account' : 'Add account';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(
                    icon: Icons.badge_outlined,
                    title: 'Account',
                    subtitle: 'Title and username are shown in the list.',
                  ),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Banking, Email',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username or email',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    icon: Icons.password_rounded,
                    title: 'Password',
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _generatePassword,
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        label: const Text('Generate'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _passwordController.text.isEmpty
                            ? null
                            : _copyPassword,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generator',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Slider(
                            min: 8,
                            max: 32,
                            divisions: 24,
                            value: _length,
                            label: _length.round().toString(),
                            onChanged: (value) =>
                                setState(() => _length = value),
                          ),
                          Text(
                            'Length: ${_length.round()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _includeUppercase,
                            title: const Text('Uppercase'),
                            onChanged: (value) =>
                                setState(() => _includeUppercase = value),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _includeLowercase,
                            title: const Text('Lowercase'),
                            onChanged: (value) =>
                                setState(() => _includeLowercase = value),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _includeNumbers,
                            title: const Text('Numbers'),
                            onChanged: (value) =>
                                setState(() => _includeNumbers = value),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _includeSymbols,
                            title: const Text('Symbols'),
                            onChanged: (value) =>
                                setState(() => _includeSymbols = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    icon: Icons.notes_rounded,
                    title: 'Notes',
                    subtitle: 'Optional — safe to leave empty.',
                  ),
                  TextFormField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Recovery codes, URL, or context…',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Saving…' : 'Save'),
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
