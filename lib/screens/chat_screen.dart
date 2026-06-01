import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final String endpoint;

  const ChatScreen({super.key, required this.endpoint});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _sending = true;
    });
    _ctrl.clear();
    _scrollToEnd();

    try {
      final uri = Uri.parse(widget.endpoint);
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': text}),
          )
          .timeout(const Duration(seconds: 10));

      String reply = '';
      try {
        final body = resp.body;
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          // common reply keys
          reply =
              decoded['reply']?.toString() ??
              decoded['answer']?.toString() ??
              decoded['response']?.toString() ??
              decoded['message']?.toString() ??
              decoded['text']?.toString() ??
              decoded['data']?.toString() ??
              body;
        } else if (decoded is String) {
          reply = decoded;
        } else {
          reply = body;
        }
      } catch (_) {
        reply = resp.body;
      }

      setState(() {
        _messages.add({'role': 'bot', 'text': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Error: $e'});
      });
    } finally {
      setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Support')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final isUser = m['role'] == 'user';
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            m['text'] ?? '',
                            style: TextStyle(
                              color: isUser
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (v) => _send(v),
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sending
                      ? const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () => _send(_ctrl.text),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
