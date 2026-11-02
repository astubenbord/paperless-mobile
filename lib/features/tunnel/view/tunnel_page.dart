import 'dart:convert';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:paperless_mobile/core/tunnel/home_network_detector.dart';
import 'package:paperless_mobile/core/tunnel/location_permission.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_diagnostics.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
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
  'server_unreachable' => '${s.tunnelErrorServer} ${s.diagLocation}',
  _ => s.tunnelErrorUnknown,
};

class TunnelPage extends StatefulWidget {
  const TunnelPage({
    super.key,
    this.initialServerUrl,
    this.diagnostics,
    this.locationPermission,
  });
  final LocationPermission? locationPermission;
  final TunnelDiagnostics? diagnostics;
  final String? initialServerUrl;
  @override
  State<TunnelPage> createState() => _TunnelPageState();
}

class _TunnelPageState extends State<TunnelPage> with WidgetsBindingObserver {
  final _ssid = TextEditingController();
  HomeNetworkResult _home = const HomeNetworkResult(
    HomeNetworkState.unknown,
    reason: HomeNetworkReason.unknown,
  );
  String? _ssidError;
  bool _settings = false;
  late final LocationPermission _permission;

  Future<void> _refreshHome() async {
    final result = await _manager.homeNetworkDetector.detect(
      _manager.homeSsids,
    );
    if (mounted) setState(() => _home = result);
  }

  Future<void> _addSsid(String value) async {
    final before = _manager.homeSsids;
    await _manager.addHomeSsid(value);
    if (!mounted) return;
    setState(() {
      _ssidError = _manager.homeSsids.length == before.length
          ? S.of(context)!.homeInvalid
          : null;
      if (_ssidError == null) _ssid.clear();
    });
    await _refreshHome();
  }

  Future<void> _useCurrent() async {
    var status = await _permission.status();
    if (_permission.isPermanentlyDenied(status)) {
      if (mounted)
        setState(() {
          _settings = true;
          _ssidError = S.of(context)!.homePermissionMissing;
        });
      return;
    }
    if (!status.isGranted) status = await _permission.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() {
        _settings = _permission.isPermanentlyDenied(status);
        _ssidError = S.of(context)!.homePermissionMissing;
      });
      return;
    }
    final result = await _manager.channel.currentSsid();
    if (!mounted) return;
    setState(() => _settings = false);
    if (result.status == SsidStatus.ok && result.ssid != null) {
      await _addSsid(result.ssid!);
    } else {
      setState(
        () => _ssidError = switch (result.status) {
          SsidStatus.locationOff => S.of(context)!.homeLocationOff,
          SsidStatus.notWifi => S.of(context)!.homeNotWifi,
          SsidStatus.permissionMissing => S.of(context)!.homePermissionMissing,
          _ => S.of(context)!.homeUnknown,
        },
      );
      await _refreshHome();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshHome();
      _permission.status().then((status) {
        if (mounted)
          setState(() => _settings = _permission.isPermanentlyDenied(status));
      });
    }
  }

  final _server = TextEditingController();
  bool _hasConfig = false;
  bool _busy = false;
  String? _message;
  bool _error = false;
  late final TunnelManager _manager;
  TunnelDiagnosticsData? _config;
  final _steps = <DiagnosticStep>[];
  DiagnosticsReport? _report;
  bool _diagnosing = false;
  bool _testFailed = false;

  Future<void> _diagnose() async {
    final uri = Uri.tryParse(_server.text.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      setState(() {
        _error = true;
        _message = S.of(context)!.tunnelInvalidUrl;
      });
      return;
    }
    setState(() {
      _diagnosing = true;
      _steps.clear();
      _report = null;
    });
    try {
      final report = await (widget.diagnostics ?? _manager.createDiagnostics())
          .run(
            uri.toString(),
            onStep: (step) {
              if (mounted) setState(() => _steps.add(step));
            },
          );
      if (!mounted) return;
      setState(() => _report = report);
      logger.fi(report.toText());
    } catch (_) {
      if (mounted)
        setState(() {
          _error = true;
          _message = S.of(context)!.diagUnknown;
        });
    } finally {
      if (mounted) setState(() => _diagnosing = false);
    }
  }

  bool _isIp(String value) => InternetAddress.tryParse(value) != null;
  bool _isCidr(String value) {
    final parts = value.split('/');
    final ip = parts.isEmpty ? null : InternetAddress.tryParse(parts.first);
    if (ip == null || parts.length > 2) return false;
    if (parts.length == 1) return true;
    final prefix = int.tryParse(parts.last);
    return prefix != null &&
        prefix >= 0 &&
        prefix <= (ip.type == InternetAddressType.IPv4 ? 32 : 128);
  }

  String _safeHost(String? host) {
    if (host == null) return '';
    if (_isIp(host)) return host;
    // Restrict host names to DNS syntax; never display arbitrary native text.
    final valid =
        host.length <= 253 &&
        host
            .split('.')
            .every(
              (label) =>
                  label.length <= 63 &&
                  RegExp(
                    r'^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$',
                  ).hasMatch(label),
            );
    return valid ? host : '';
  }

  String _stepDetail(S s, DiagnosticStep step) {
    final details = <String>[
      switch (step.status) {
        DiagnosticStatus.ok => s.diagOk,
        DiagnosticStatus.warn => s.diagWarn,
        DiagnosticStatus.error => s.diagError,
        DiagnosticStatus.skipped => s.diagSkipped,
      },
    ];
    if (step.id == 'home_network') {
      details.add(switch (step.data['state']) {
        'atHome' => s.homeNoTunnel,
        'away' => s.homeAway,
        _ => s.homeUnrecognized(switch (step.data['reason']) {
          'noHomeSsids' => s.homeNoNames,
          'permissionMissing' => s.homePermissionMissing,
          'locationOff' => s.homeLocationOff,
          _ => s.homeUnknown,
        }),
      });
    }
    if (step.id == 'verdict' && _report != null) {
      details.add(_verdict(s, _report!.verdict));
    }
    if (step.id == 'vpnDns' && step.status == DiagnosticStatus.warn) {
      details.add(s.diagDnsOutside);
    }
    // Select only fields whose type and range can be validated. Never show
    // arbitrary diagnostic strings, exception messages or platform maps.
    if (step.id == 'tcp') {
      final ip = step.data['ip'];
      final port = step.data['port'];
      final milliseconds = step.data['milliseconds'];
      if (ip is String && _isIp(ip)) details.add('${s.diagAddress}: $ip');
      if (port is int && port > 0 && port <= 65535)
        details.add('${s.diagPortLabel}: $port');
      if (milliseconds is int && milliseconds >= 0 && milliseconds < 3600000) {
        details.add(s.diagDuration(milliseconds));
      }
    }
    if (step.id == 'http') {
      final code = step.data['status'];
      if (code is int && code >= 100 && code <= 599)
        details.add(s.diagHttpStatus(code));
    }
    return details.join('\n');
  }

  String _stepTitle(S s, String id) => switch (id) {
    'home_network' => s.homeTitle,
    'tunnel' => s.diagTunnel,
    'config' => s.diagConfig,
    'systemDns' => s.diagSystemDns,
    'vpnDns' => s.diagVpnDns,
    'tcp' => s.diagTcp,
    'http' => s.diagHttp,
    _ => s.diagVerdict,
  };
  String _verdict(S s, DiagnosticsVerdict v) => switch (v) {
    DiagnosticsVerdict.tunnelDown => s.diagTunnelDown,
    DiagnosticsVerdict.dnsOutsideTunnel => s.diagDnsOutside,
    DiagnosticsVerdict.portUnreachable => s.diagPort,
    DiagnosticsVerdict.notPaperless => s.diagPaperless,
    DiagnosticsVerdict.tlsError => s.diagTls,
    DiagnosticsVerdict.connectionOk => s.diagSuccess,
    DiagnosticsVerdict.unknown => s.diagUnknown,
  };

  @override
  void initState() {
    super.initState();
    _server.text = widget.initialServerUrl ?? '';
    _manager = context.read<TunnelManager>();
    _permission = widget.locationPermission ?? LocationPermissionHandler();
    WidgetsBinding.instance.addObserver(this);
    _refreshHome();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final exists = await _manager.channel.hasConfig();
      if (exists) {
        await _manager.refreshStatus();
        try {
          _config = await _manager.channel.diagnostics();
        } catch (_) {
          _config = null;
        }
      }
      if (mounted) setState(() => _hasConfig = exists);
    } on TunnelException catch (e) {
      if (mounted)
        setState(() {
          _error = true;
          _message = tunnelErrorMessage(S.of(context)!, e.code);
        });
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    bool connectionTest = false,
  }) async {
    setState(() {
      _busy = true;
      _message = null;
      _error = false;
      _testFailed = false;
    });
    try {
      await action();
    } on TunnelException catch (e) {
      if (mounted)
        setState(() {
          _error = true;
          _message = tunnelErrorMessage(S.of(context)!, e.code);
          _testFailed = connectionTest;
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
    await _manager.channel.importConfig(text);
    try {
      _config = await _manager.channel.diagnostics();
    } catch (_) {
      _config = null;
    }
    if (mounted)
      setState(() {
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
    WidgetsBinding.instance.removeObserver(this);
    _ssid.dispose();
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
          if (_config case final config?) ...[
            Text('${s.diagDns}: ${config.dnsServers.where(_isIp).join(', ')}'),
            if (config.dnsServers.isEmpty) Text(s.diagDnsMissing),
            Text(
              '${s.diagAddress}: ${config.interfaceAddresses.where(_isCidr).join(', ')}',
            ),
            for (final peer in config.peers) ...[
              Text(
                '${s.diagEndpoint}: ${_safeHost(peer.endpointHost)}${peer.endpointPort == null ? '' : ':${peer.endpointPort}'}',
              ),
              Text(
                '${s.diagAllowed}: ${peer.allowedIps.where(_isCidr).join(', ')}',
              ),
            ],
          ],
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
                    }, connectionTest: true),
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
          if (_testFailed)
            TextButton(
              onPressed: _diagnosing
                  ? null
                  : () {
                      _diagnose();
                    },
              child: Text(s.diagDetails),
            ),
          const Divider(),
          Text(s.diagTitle, style: Theme.of(context).textTheme.titleMedium),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _diagnosing ? null : _diagnose,
              child: Text(s.diagRun),
            ),
          ),
          if (_diagnosing) const LinearProgressIndicator(),
          for (final step in _steps)
            ListTile(
              leading: Icon(switch (step.status) {
                DiagnosticStatus.ok => Icons.check_circle,
                DiagnosticStatus.warn => Icons.warning_amber,
                DiagnosticStatus.error => Icons.error,
                DiagnosticStatus.skipped => Icons.skip_next,
              }),
              title: Text(_stepTitle(s, step.id)),
              subtitle: Text(switch (step.status) {
                DiagnosticStatus.ok => s.diagOk,
                DiagnosticStatus.warn => s.diagWarn,
                DiagnosticStatus.error => s.diagError,
                DiagnosticStatus.skipped => s.diagSkipped,
              }),
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(_stepTitle(s, step.id)),
                  content: Text(_stepDetail(s, step)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.tunnelCancel),
                    ),
                  ],
                ),
              ),
            ),
          if (_report case final report?) ...[
            Card(
              color: switch (report.verdict) {
                DiagnosticsVerdict.connectionOk => Theme.of(
                  context,
                ).colorScheme.primaryContainer,
                DiagnosticsVerdict.dnsOutsideTunnel ||
                DiagnosticsVerdict.unknown => Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
                _ => Theme.of(context).colorScheme.errorContainer,
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_verdict(s, report.verdict)),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: report.toText()));
                if (context.mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s.diagCopied)));
              },
              child: Text(s.diagCopy),
            ),
          ],
          const Divider(),
          ValueListenableBuilder<TunnelViewState>(
            valueListenable: _manager.state,
            builder: (context, state, _) => ListTile(
              title: Text(
                state.atHome
                    ? s.homeNoTunnel
                    : switch (state.state) {
                        TunnelConnectionState.off => s.tunnelStatusOff,
                        TunnelConnectionState.connecting =>
                          s.tunnelStatusConnecting,
                        TunnelConnectionState.connected =>
                          s.tunnelStatusConnected,
                        TunnelConnectionState.error => s.tunnelStatusError,
                      },
              ),
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
          const Divider(),
          Text(s.homeTitle, style: Theme.of(context).textTheme.titleMedium),
          Text(s.homeExplanation),
          Text(s.homePrivacy),
          for (final name in _manager.homeSsids)
            ListTile(
              title: Text(name),
              trailing: IconButton(
                tooltip: s.homeDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await _manager.removeHomeSsid(name);
                  if (mounted) setState(() {});
                  await _refreshHome();
                },
              ),
            ),
          TextField(
            controller: _ssid,
            decoration: InputDecoration(
              labelText: s.homeName,
              errorText: _ssidError,
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => _addSsid(_ssid.text),
                child: Text(s.homeAdd),
              ),
              OutlinedButton(
                onPressed: _useCurrent,
                child: Text(s.homeUseCurrent),
              ),
              if (_settings)
                OutlinedButton(
                  onPressed: () => _permission.openSettings(),
                  child: Text(s.homeOpenSettings),
                ),
            ],
          ),
          Text(
            s.homeNow +
                ' ' +
                switch (_home.state) {
                  HomeNetworkState.atHome => s.homeAtHome(_home.ssid ?? ''),
                  HomeNetworkState.away => s.homeAway,
                  HomeNetworkState.unknown => s.homeUnrecognized(
                    switch (_home.reason) {
                      HomeNetworkReason.noHomeSsids => s.homeNoNames,
                      HomeNetworkReason.permissionMissing =>
                        s.homePermissionMissing,
                      HomeNetworkReason.locationOff => s.homeLocationOff,
                      _ => s.homeUnknown,
                    },
                  ),
                },
          ),
          SwitchListTile(
            title: Text(s.tunnelDirect),
            subtitle: Text(s.homeDirectHint),
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
                            _config = null;
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
