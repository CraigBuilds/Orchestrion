import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

/// A dedicated full-screen log viewer for a single service.
class LogScreen extends StatefulWidget {
  final String serviceName;

  const LogScreen({super.key, required this.serviceName});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final List<String> _lines = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _subscription;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _loadInitialLogs();
    _startStreaming();
  }

  Future<void> _loadInitialLogs() async {
    final appState = context.read<AppState>();
    final logs = await appState.getLogs(widget.serviceName, lines: 200);
    if (mounted) {
      setState(() {
        _lines.addAll(logs);
      });
      _scrollToBottom();
    }
  }

  void _startStreaming() {
    final appState = context.read<AppState>();
    _subscription = appState.streamLogs(widget.serviceName).listen((line) {
      if (mounted) {
        setState(() {
          _lines.add(line);
          // Keep max 2000 lines
          if (_lines.length > 2000) {
            _lines.removeAt(0);
          }
        });
        if (_autoScroll) {
          _scrollToBottom();
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs: ${widget.serviceName}'),
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.lock : Icons.lock_open),
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
              if (_autoScroll) _scrollToBottom();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: () {
              setState(() {
                _lines.clear();
              });
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: _lines.isEmpty
            ? const Center(
                child: Text(
                  'No logs yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: _lines.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  return Text(
                    _lines[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.greenAccent,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
