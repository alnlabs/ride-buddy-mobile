import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/providers/auth_provider.dart';
import 'package:ridebuddy/providers/chat_provider.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/loading_skeleton.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    try {
      await ref.read(chatThreadProvider(widget.conversationId).notifier).send(text);
      _controller.clear();
      _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
      final err = ref.read(chatThreadProvider(widget.conversationId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Could not send')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatThreadProvider(widget.conversationId));
    final me = ref.watch(authStateProvider).userId;
    final peerName = state.conversation?.peer.displayName ?? 'Chat';

    ref.listen(chatThreadProvider(widget.conversationId), (prev, next) {
      if (prev == null || next.messages.length > (prev.messages.length)) {
        _scrollToEnd();
      }
    });

    return SkyScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(peerName),
            if (state.conversation != null)
              Text(
                state.conversation!.iAmHost ? 'Co-rider' : 'Host',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(chatThreadProvider(widget.conversationId).notifier).reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      child: Column(
        children: [
          if (state.conversation != null)
            Material(
              color: AppTheme.surfaceElevated,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '${state.conversation!.rideOriginLabel ?? 'From'} → ${state.conversation!.rideDestinationLabel ?? 'To'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          Expanded(
            child: state.loading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: LoadingSkeleton(count: 4),
                  )
                : state.messages.isEmpty
                    ? Center(
                        child: Text(
                          state.canSend
                              ? 'Say hello — keep it about the commute'
                              : 'Chat history (messaging closed)',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.inkMuted,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) {
                          final m = state.messages[i];
                          final mine = m.senderId == me;
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                              decoration: BoxDecoration(
                                color: mine
                                    ? AppTheme.brandBlue.withValues(alpha: 0.14)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.line),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(m.body, style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat.jm().format(m.createdAt),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppTheme.inkMuted,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: state.canSend && !state.sending,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: state.canSend ? 'Message…' : 'Chat closed',
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.line),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.canSend && !state.sending ? _send : null,
                    icon: state.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
