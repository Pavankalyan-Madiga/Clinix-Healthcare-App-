import 'package:clinix/features/messaging/data/domain/entites/message.dart';
import 'package:clinix/providers/auth_providers.dart';
import 'package:clinix/providers/message_providers.dart';
import 'package:clinix/features/messaging/data/model/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/message_bubble.dart';

class ConversationPage extends ConsumerStatefulWidget {
  final String staffId;
  final String staffName;
  final String conversationId;

  const ConversationPage({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.conversationId,
  });

  @override
  ConsumerState<ConversationPage> createState() =>
      _ConversationPageState();
}

class _ConversationPageState
    extends ConsumerState<ConversationPage> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  bool _isSending = false;
  bool _markingAsRead = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content =
        _messageController.text.trim();

    if (content.isEmpty || _isSending) {
      return;
    }

    final currentStaff =
        ref.read(authStateProvider);

    if (currentStaff == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No authenticated staff session.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSending = true;
    });

    final message = MessageModel(
      id:
          'MSG-${DateTime.now().microsecondsSinceEpoch}',
      conversationId:
          widget.conversationId,
      senderId:
          currentStaff.id,
      senderName:
          currentStaff.name,
      receiverId:
          widget.staffId,
      receiverName:
          widget.staffName,
      content:
          content,
      createdAt:
          DateTime.now(),
      status:
          MessageStatus.sending,
      isRead: true,
    );

    try {
      await ref
          .read(messageRepositoryProvider)
          .sendMessage(message);

      _messageController.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSending = false;
      });

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to send message: $error',
          ),
        ),
      );
    }
  }

  Future<void> _markIncomingMessagesAsRead(
    List<MessageModel> messages,
  ) async {
    if (_markingAsRead) {
      return;
    }

    final currentStaff =
        ref.read(authStateProvider);

    if (currentStaff == null) {
      return;
    }

    final unreadMessages = messages.where(
      (message) =>
          message.receiverId == currentStaff.id &&
          !message.isRead,
    );

    if (unreadMessages.isEmpty) {
      return;
    }

    _markingAsRead = true;

    try {
      final repository =
          ref.read(messageRepositoryProvider);

      for (final message in unreadMessages) {
        await repository.markAsRead(
          message.id,
        );
      }
    } finally {
      _markingAsRead = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
              const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      final value = parts.first;

      return value
          .substring(
            0,
            value.length >= 2 ? 2 : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour % 12 == 0
            ? 12
            : time.hour % 12;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final repository =
        ref.watch(messageRepositoryProvider);

    final currentStaff =
        ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F9FC),
        elevation: 0,
        surfaceTintColor:
            Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
              child: Text(
                _initials(widget.staffName),
                style: TextStyle(
                  color:
                      Theme.of(context)
                          .colorScheme
                          .primary,
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.staffName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w700,
                ),
                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                List<MessageModel>>(
              stream: repository
                  .watchMessagesByConversationId(
                widget.conversationId,
              ),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load messages.',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                final messages =
                    snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback(
                  (_) {
                    _scrollToBottom();

                    _markIncomingMessagesAsRead(
                      messages,
                    );
                  },
                );

                return ListView.builder(
                  controller:
                      _scrollController,
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    24,
                  ),
                  itemCount:
                      messages.length,
                  itemBuilder:
                      (context, index) {
                    final message =
                        messages[index];

                    final isMine =
                        currentStaff != null &&
                        message.senderId ==
                            currentStaff.id;

                    return MessageBubble(
                      message:
                          message.content,
                      isMine:
                          isMine,
                      time:
                          _formatTime(
                        message.createdAt,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FC),
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE5E8ED),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _messageController,
                    textInputAction:
                        TextInputAction.newline,
                    minLines: 1,
                    maxLines: 4,
                    decoration:
                        InputDecoration(
                      hintText:
                          'Message...',
                      filled: true,
                      fillColor:
                          Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              Color(0xFFDCE0E5),
                        ),
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              Color(0xFFDCE0E5),
                        ),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),
                        borderSide:
                            BorderSide(
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isSending
                      ? null
                      : _sendMessage,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        _isSending
                            ? Colors.grey
                            : const Color(
                                0xFF31547D,
                              ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}