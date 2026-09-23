import 'package:clinix/features/messaging/data/staff_directory.dart';
import 'package:clinix/providers/auth_providers.dart';
import 'package:clinix/providers/message_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/domain/entites/message.dart' as domain;
import '../data/repositories/message_repository.dart';
import 'conversation_page.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() =>
      _MessagesPageState();
}

class _MessagesPageState
    extends ConsumerState<MessagesPage> {
  List<domain.Message> _messages = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final repository =
          ref.read(messageRepositoryProvider);

      final messages =
          await repository.getAllMessages();

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    }
  }

  String _currentStaffId() {
    final staff =
        ref.read(authStateProvider);

    return staff?.id ?? 'STAFF-001';
  }

  domain.Message? _latestMessage(
    String staffId,
  ) {
    final conversationId =
        MessageRepository.conversationIdFor(
      _currentStaffId(),
      staffId,
    );

    final messages = _messages
        .where(
          (message) =>
              message.conversationId ==
              conversationId,
        )
        .toList();

    if (messages.isEmpty) {
      return null;
    }

    messages.sort(
      (a, b) =>
          b.createdAt.compareTo(a.createdAt),
    );

    return messages.first;
  }

  Future<void> _openConversation(
    StaffContact staff,
  ) async {
    final conversationId =
        MessageRepository.conversationIdFor(
      _currentStaffId(),
      staff.id,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationPage(
          staffId: staff.id,
          staffName: staff.name,
          conversationId: conversationId,
        ),
      ),
    );

    await _loadMessages();
  }

  List<StaffContact> _buildContacts(
    String currentStaffId,
  ) {
    final contacts =
        StaffDirectory.getOtherStaff(
      currentStaffId,
    )
        .map(
          (staff) => StaffContact(
            id: staff.id,
            name: staff.name,
            role: staff.role,
          ),
        )
        .toList();

    final contactIds =
        contacts.map((contact) => contact.id).toSet();

    for (final message in _messages) {
      String? otherStaffId;
      String? otherStaffName;

      if (message.senderId == currentStaffId &&
          message.receiverId != currentStaffId) {
        otherStaffId = message.receiverId;
        otherStaffName = message.receiverName;
      } else if (message.receiverId == currentStaffId &&
          message.senderId != currentStaffId) {
        otherStaffId = message.senderId;
        otherStaffName = message.senderName;
      }

      if (otherStaffId == null ||
          otherStaffName == null ||
          otherStaffId.isEmpty ||
          otherStaffName.isEmpty) {
        continue;
      }

      if (!contactIds.contains(otherStaffId)) {
        contacts.add(
          StaffContact(
            id: otherStaffId,
            name: otherStaffName,
            role: 'Clinical Staff',
          ),
        );

        contactIds.add(otherStaffId);
      }
    }

    contacts.sort(
      (a, b) {
        final aMessage =
            _latestMessage(a.id);

        final bMessage =
            _latestMessage(b.id);

        if (aMessage == null &&
            bMessage == null) {
          return 0;
        }

        if (aMessage == null) {
          return 1;
        }

        if (bMessage == null) {
          return -1;
        }

        return bMessage.createdAt.compareTo(
          aMessage.createdAt,
        );
      },
    );

    return contacts;
  }

  @override
  Widget build(BuildContext context) {
    final currentStaff =
        ref.watch(authStateProvider);

    final currentStaffId =
        currentStaff?.id ?? 'STAFF-001';

    final contacts =
        _buildContacts(currentStaffId);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8FAFD),
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: Color(0xFF20242A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showNewMessage,
            icon: const Icon(
              Icons.edit_outlined,
              size: 28,
              color: Color(0xFF454B53),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.only(
                top: 8,
                bottom: 20,
              ),
              itemCount:
                  contacts.length,
              itemBuilder:
                  (context, index) {
                final staff =
                    contacts[index];

                return _buildStaffRow(
                  staff,
                  currentStaffId,
                );
              },
            ),
    );
  }

  Widget _buildStaffRow(
    StaffContact staff,
    String currentStaffId,
  ) {
    final latest =
        _latestMessage(staff.id);

    final conversationId =
        MessageRepository.conversationIdFor(
      currentStaffId,
      staff.id,
    );

    final unread = _messages
        .where(
          (message) =>
              message.conversationId ==
                  conversationId &&
              message.receiverId ==
                  currentStaffId &&
              !message.isRead,
        )
        .length;

    return InkWell(
      onTap: () {
        _openConversation(staff);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        decoration:
            const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE9EDF2),
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor:
                  const Color(0xFFDCE8F8),
              child: Text(
                staff.initials,
                style: const TextStyle(
                  color: Color(0xFF31547D),
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(0xFF20242A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    latest?.content ??
                        staff.role,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: latest == null
                          ? const Color(
                              0xFF737A83,
                            )
                          : const Color(
                              0xFF555C65,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (latest != null)
              Padding(
                padding:
                    const EdgeInsets.only(
                  left: 10,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(
                        latest.createdAt,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            Color(0xFF858B93),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(height: 5),
                      Container(
                        width: 20,
                        height: 20,
                        alignment:
                            Alignment.center,
                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xFF31547D),
                          shape:
                              BoxShape.circle,
                        ),
                        child: Text(
                          unread.toString(),
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showNewMessage() {
    final currentStaff =
        ref.read(authStateProvider);

    final currentStaffId =
        currentStaff?.id ?? 'STAFF-001';

    final contacts =
        _buildContacts(currentStaffId);

    showModalBottomSheet(
      context: context,
      backgroundColor:
          const Color(0xFFF8FAFD),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding:
                    EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  12,
                ),
                child: Text(
                  'New Message',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              for (final staff in contacts)
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        const Color(
                      0xFFDCE8F8,
                    ),
                    child: Text(
                      staff.initials,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF31547D),
                      ),
                    ),
                  ),
                  title:
                      Text(staff.name),
                  subtitle:
                      Text(staff.role),
                  onTap: () {
                    Navigator.pop(context);
                    _openConversation(
                      staff,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(
    DateTime time,
  ) {
    final hour =
        time.hour % 12 == 0
            ? 12
            : time.hour % 12;

    final minute =
        time.minute
            .toString()
            .padLeft(2, '0');

    final period =
        time.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }
}

class StaffContact {
  final String id;
  final String name;
  final String role;

  const StaffContact({
    required this.id,
    required this.name,
    required this.role,
  });

  String get initials {
    final parts =
        name.trim().split(
          RegExp(r'\s+'),
        );

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}