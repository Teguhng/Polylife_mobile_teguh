import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/ai/services/ai_chat_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _service = AiChatService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  List<Map<String, dynamic>> _sessions = [];
  int? _sessionId;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _service.sessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(error);
      });
    }
  }

  Future<void> _openSession(Map<String, dynamic> session) async {
    final id = (session['id'] as num?)?.toInt();
    if (id == null) return;
    setState(() {
      _loading = true;
      _sessionId = id;
      _messages.clear();
      _error = null;
    });
    try {
      final result = await _service.messages(id);
      final rows = (result['messages'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => _ChatMessage(
                role: row['role']?.toString() ?? 'assistant',
                content: row['content']?.toString() ?? '',
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _messages.addAll(rows);
        _loading = false;
      });
      _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(error);
      });
    }
  }

  void _newConversation() {
    setState(() {
      _sessionId = null;
      _messages.clear();
      _error = null;
    });
  }

  Future<void> _send() async {
    final prompt = _input.text.trim();
    if (prompt.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _sending = true;
      _error = null;
      _messages.add(_ChatMessage(role: 'user', content: prompt));
    });
    _scrollToEnd();
    try {
      final accepted = await _service.send(prompt, sessionId: _sessionId);
      _sessionId = (accepted['session_id'] as num?)?.toInt();
      final runId = (accepted['run_id'] as num?)?.toInt();
      if (runId == null) throw Exception('AI tidak mengembalikan status proses.');
      Map<String, dynamic> result = const {};
      for (var attempt = 0; attempt < 180; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        result = await _service.run(runId);
        if (result['status'] == 'success') break;
        if (result['status'] == 'failed' || result['status'] == 'cancelled') {
          throw Exception(result['message']?.toString() ?? 'AI gagal menjawab.');
        }
      }
      if (result['status'] != 'success') {
        throw Exception('Respons AI belum selesai. Coba buka percakapan lagi.');
      }
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: result['reply']?.toString() ?? 'AI tidak memberikan jawaban.',
        ));
      });
      await _loadSessions();
      _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _messageFor(Object error) => error.toString().replaceFirst('Exception: ', '');

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PolyBot'),
            Text('Sahabat Mahasiswa', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Percakapan baru',
            onPressed: _newConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          PopupMenuButton<int>(
            tooltip: 'Percakapan terbaru',
            icon: const Icon(Icons.history_rounded),
            onSelected: (index) => _openSession(_sessions[index]),
            itemBuilder: (context) => [
              for (var i = 0; i < _sessions.length; i++)
                PopupMenuItem(
                  value: i,
                  child: SizedBox(
                    width: 230,
                    child: Text(
                      _sessions[i]['title']?.toString() ?? 'Percakapan',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              if (_sessions.isEmpty)
                const PopupMenuItem(enabled: false, child: Text('Belum ada percakapan')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _welcome()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const _TypingBubble();
                          }
                          return _MessageBubble(message: _messages[index]);
                        },
                      ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Tanya atau minta bantuan…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Kirim pesan',
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcome() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 38),
              const SizedBox(height: 16),
              const Text(
                'Halo! Apa yang ingin kamu bereskan?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Tanya tentang kegiatan, keuangan, jadwal, atau hal lain.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appFaint),
              ),
            ],
          ),
        ),
      );
}

class _ChatMessage {
  final String role;
  final String content;
  const _ChatMessage({required this.role, required this.content});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .84),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? context.appPrimary.withValues(alpha: .22) : context.appSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorder),
        ),
        child: SelectableText(message.content),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Chip(
            avatar: const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: const Text('PolyBot sedang berpikir…'),
            backgroundColor: context.appSurface,
          ),
        ),
      );
}
