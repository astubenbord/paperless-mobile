import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_channel.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_manager.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

String tunnelErrorMessage(S s, String code) => switch (code) {
  'vpn_not_authorized' => s.tunnelErrorPermission,
  'dns_failure' => s.tunnelErrorDns,
  'config_missing' => s.tunnelErrorMissing,
  'vpn_start_failed' => s.tunnelErrorStart,
  'tun_failed' => s.tunnelErrorTun,
  'library_missing' => s.tunnelErrorLibrary,
  'config_too_large' => s.tunnelErrorLarge,
  'config_invalid' => s.tunnelErrorInvalid,
  'server_unreachable' => s.tunnelErrorServer,
  _ => s.tunnelErrorUnknown,
};

class TunnelPage extends StatefulWidget {
  const TunnelPage({super.key, this.initialServerUrl});
  final String? initialServerUrl;
  @override
  State<TunnelPage> createState() => _TunnelPageState();
}

class _TunnelPageState extends State<TunnelPage> {
  final _server = TextEditingController();
  bool _hasConfig = false;
  bool _busy = false;
  TunnelConfigInfo? _info;
  String? _message;
  bool _error = false;
  late final TunnelManager _manager;

  @override
  void initState() {
    super.initState();
    _server.text = widget.initialServerUrl ?? '';
    _manager = context.read<TunnelManager>();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final exists = await _manager.channel.hasConfig();
      if (exists) await _manager.refreshStatus();
      if (mounted) setState(() => _hasConfig = exists);
    } on TunnelException catch (e) {
      if (mounted)
        setState(() {
          _error = true;
          _message = tunnelErrorMessage(S.of(context)!, e.code);
        });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
      _error = false;
    });
    try {
      await action();
    } on TunnelException catch (e) {
      if (mounted)
        setState(() {
          _error = true;
          _message = tunnelErrorMessage(S.of(context)!, e.code);
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = true;
          _message = S.of(context)!.tunnelErrorUnknown;
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(String text) async {
    if (utf8.encode(text).length > 65536)
      throw const TunnelException('config_too_large');
    final info = await _manager.channel.importConfig(text);
    if (mounted)
      setState(() {
        _info = info;
        _hasConfig = true;
        _message = S.of(context)!.tunnelConfigSaved;
      });
  }

  Future<void> _pick() => _run(() async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['conf'],
      withData: false,
    );
    if (selection == null) return;
    final entry = selection.files.single;
    if (entry.size > 65536) throw const TunnelException('config_too_large');
    if (entry.path == null) throw const TunnelException('config_invalid');
    final file = File(entry.path!);
    if (await file.length() > 65536)
      throw const TunnelException('config_too_large');
    final bytes = await file
        .openRead(0, 65537)
        .fold<List<int>>([], (a, b) => a..addAll(b));
    if (bytes.length > 65536) throw const TunnelException('config_too_large');
    try {
      await _import(utf8.decode(bytes));
    } on FormatException {
      throw const TunnelException('config_invalid');
    }
  });

  Future<void> _paste() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context)!.tunnelPaste),
        content: TextField(
          controller: controller,
          maxLines: 8,
          obscureText: false,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(labelText: S.of(context)!.tunnelPaste),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context)!.tunnelCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(S.of(context)!.tunnelSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text != null && mounted) await _run(() => _import(text));
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.tunnelTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.tunnelStep1, style: Theme.of(context).textTheme.titleMedium),
          Text(_hasConfig ? s.tunnelConfigExists : s.tunnelConfigNone),
          if (_info case final info?)
            Text(
              s.tunnelInfo(
                info.endpointHost,
                info.peerCount.toString(),
                info.interfaceAddresses.join(', '),
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.upload_file),
                label: Text(s.tunnelImport),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _paste,
                child: Text(s.tunnelPaste),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(s.tunnelStep2, style: Theme.of(context).textTheme.titleMedium),
          Text(s.tunnelPermissionHelp),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      if (!await _manager.channel.requestPermission())
                        throw const TunnelException('vpn_not_authorized');
                      if (mounted) setState(() => _message = s.tunnelGranted);
                    }),
              child: Text(s.tunnelPermission),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.tunnelStep3, style: Theme.of(context).textTheme.titleMedium),
          TextField(
            controller: _server,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: s.tunnelServerUrl),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      final uri = Uri.tryParse(_server.text.trim());
                      if (uri == null ||
                          !['http', 'https'].contains(uri.scheme) ||
                          uri.host.isEmpty) {
                        if (mounted)
                          setState(() {
                            _error = true;
                            _message = s.tunnelInvalidUrl;
                          });
                        return;
                      }
                      await _manager.testConnection(uri.toString());
                      if (mounted) setState(() => _message = s.tunnelTestOk);
                    }),
              child: Text(s.tunnelTest),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_message != null)
            Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                style: TextStyle(
                  color: _error ? Theme.of(context).colorScheme.error : null,
                ),
              ),
            ),
          const Divider(),
          ValueListenableBuilder<TunnelViewState>(
            valueListenable: _manager.state,
            builder: (context, state, _) => ListTile(
              title: Text(switch (state.state) {
                TunnelConnectionState.off => s.tunnelStatusOff,
                TunnelConnectionState.connecting => s.tunnelStatusConnecting,
                TunnelConnectionState.connected => s.tunnelStatusConnected,
                TunnelConnectionState.error => s.tunnelStatusError,
              }),
              subtitle: state.errorCode == null
                  ? null
                  : Text(tunnelErrorMessage(s, state.errorCode!)),
            ),
          ),
          SwitchListTile(
            title: Text(s.tunnelAuto),
            value: _manager.enabled,
            onChanged: _busy
                ? null
                : (v) async {
                    await _manager.setEnabled(v);
                    if (mounted) setState(() {});
                  },
          ),
          SwitchListTile(
            title: Text(s.tunnelDirect),
            value: _manager.directCheck,
            onChanged: _busy
                ? null
                : (v) async {
                    await _manager.setDirectCheck(v);
                    if (mounted) setState(() {});
                  },
          ),
          DropdownButtonFormField<int>(
            initialValue: _manager.delayMinutes,
            decoration: InputDecoration(labelText: s.tunnelDelay),
            items: [
              DropdownMenuItem(value: 1, child: Text(s.tunnelMinutes1)),
              DropdownMenuItem(value: 5, child: Text(s.tunnelMinutes5)),
              DropdownMenuItem(value: 15, child: Text(s.tunnelMinutes15)),
              DropdownMenuItem(value: 30, child: Text(s.tunnelMinutes30)),
              DropdownMenuItem(value: 0, child: Text(s.tunnelNever)),
            ],
            onChanged: _busy
                ? null
                : (v) async {
                    if (v != null) {
                      await _manager.setDelayMinutes(v);
                      if (mounted) setState(() {});
                    }
                  },
          ),
          TextButton.icon(
            onPressed: _busy || !_hasConfig
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(s.tunnelDelete),
                        content: Text(s.tunnelDeleteConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(s.tunnelCancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(s.tunnelDeleteAction),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && mounted)
                      await _run(() async {
                        await _manager.deleteConfig();
                        if (mounted)
                          setState(() {
                            _hasConfig = false;
                            _info = null;
                          });
                      });
                  },
            icon: const Icon(Icons.delete_outline),
            label: Text(s.tunnelDelete),
          ),
        ],
      ),
    );
  }
}
