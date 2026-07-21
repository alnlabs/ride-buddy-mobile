import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ridebuddy/providers/chat_provider.dart';
import 'package:ridebuddy/services/api_client.dart';
import 'package:ridebuddy/theme/app_theme.dart';
import 'package:ridebuddy/widgets/common/empty_state.dart';
import 'package:ridebuddy/widgets/common/error_view.dart';
import 'package:ridebuddy/widgets/common/loading_skeleton.dart';
import 'package:ridebuddy/widgets/common/ui_kit.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatInboxProvider);
    return SkyScaffold(
      appBar: AppBar(title: const Text('Messages')),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingSkeleton(),
        ),
        error: (e, _) => ErrorView(
          message: ref.read(apiClientProvider).messageFrom(e),
          onRetry: () => ref.invalidate(chatInboxProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SoftPanel(
                child: EmptyState(
                  title: 'No chats yet',
                  subtitle: 'Message a host or co-rider after you request a seat or send an offer',
                  icon: Icons.chat_bubble_outline_rounded,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(chatInboxProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = list[i];
                final when = c.lastMessageAt != null
                    ? DateFormat.MMMd().add_jm().format(c.lastMessageAt!)
                    : null;
                return SoftPanel(
                  onTap: () => context.push('/chat/${c.id}'),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.brandBlue.withValues(alpha: 0.12),
                        child: Text(
                          c.peer.displayName.isNotEmpty
                              ? c.peer.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppTheme.brandBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.peer.displayName,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandOrange.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    c.iAmHost ? 'Co-rider' : 'Host',
                                    style: const TextStyle(
                                      color: AppTheme.brandOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${c.rideOriginLabel ?? 'From'} → ${c.rideDestinationLabel ?? 'To'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.inkMuted,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (c.lastMessagePreview != null && c.lastMessagePreview!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                c.lastMessagePreview!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight:
                                          c.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                                    ),
                              ),
                            ],
                            if (when != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                when,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.inkMuted,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (c.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.brandOrange,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
