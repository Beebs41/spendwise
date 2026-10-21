import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/transaction_repository.dart';

class NotificationsSheet extends StatefulWidget {
  final TransactionRepository repository;

  const NotificationsSheet({super.key, required this.repository});

  static Future<void> show(BuildContext context, {required TransactionRepository repository}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationsSheet(repository: repository),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  bool _showUnreadOnly = false;

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'budget_exceeded':
        return AppColors.darkDanger;
      case 'budget_warning':
        return AppColors.darkWarning;
      case 'goal_completed':
        return AppColors.darkSuccess;
      case 'goal_milestone':
        return AppColors.darkPrimary;
      case 'debt_due':
        return const Color(0xFFE056FD);
      case 'recurring':
        return AppColors.darkAccent;
      default:
        return AppColors.darkPrimary;
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: AppColors.darkDanger),
            SizedBox(width: 10),
            Text('Clear Notifications', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repository.clearAllNotifications();
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.darkPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.darkPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Budgets, goals & reminders',
                            style: TextStyle(
                              color: AppColors.darkTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.done_all_rounded, color: AppColors.darkAccent, size: 22),
                      tooltip: 'Mark all as read',
                      onPressed: () async {
                        await widget.repository.markAllNotificationsAsRead();
                        HapticFeedback.lightImpact();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.darkDanger, size: 22),
                      tooltip: 'Clear all',
                      onPressed: () => _confirmClearAll(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    FilterChip(
                      selected: !_showUnreadOnly,
                      label: const Text('All'),
                      labelStyle: TextStyle(
                        color: !_showUnreadOnly ? Colors.black : AppColors.darkTextSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      backgroundColor: AppColors.darkCard,
                      selectedColor: AppColors.darkPrimary,
                      checkmarkColor: Colors.black,
                      side: BorderSide(
                        color: !_showUnreadOnly ? AppColors.darkPrimary : AppColors.darkBorder,
                      ),
                      onSelected: (_) => setState(() => _showUnreadOnly = false),
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<int>(
                      stream: widget.repository.watchUnreadNotificationCount(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return FilterChip(
                          selected: _showUnreadOnly,
                          label: Text('Unread ($unreadCount)'),
                          labelStyle: TextStyle(
                            color: _showUnreadOnly ? Colors.black : AppColors.darkTextSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: AppColors.darkCard,
                          selectedColor: AppColors.darkPrimary,
                          checkmarkColor: Colors.black,
                          side: BorderSide(
                            color: _showUnreadOnly ? AppColors.darkPrimary : AppColors.darkBorder,
                          ),
                          onSelected: (_) => setState(() => _showUnreadOnly = true),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Divider(color: AppColors.darkBorder, height: 1),

              // Notification List
              Expanded(
                child: StreamBuilder<List<AppNotification>>(
                  stream: widget.repository.watchNotifications(unreadOnly: _showUnreadOnly),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.darkPrimary),
                      );
                    }

                    final notifications = snapshot.data ?? [];

                    if (notifications.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: AppColors.darkCard,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.darkBorder),
                                ),
                                child: const Center(
                                  child: Text('🔔', style: TextStyle(fontSize: 32)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _showUnreadOnly ? 'No Unread Notifications' : 'No Notifications Yet',
                                style: const TextStyle(
                                  color: AppColors.darkTextPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _showUnreadOnly
                                    ? 'You have caught up with all financial reminders!'
                                    : 'Budget warnings, debt deadlines, and savings milestones will appear here.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.darkTextSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final typeColor = _getTypeColor(notification.type);

                        return Dismissible(
                          key: Key('notification_${notification.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.darkDanger.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: AppColors.darkDanger),
                          ),
                          onDismissed: (_) {
                            widget.repository.deleteNotification(notification.id);
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (!notification.isRead) {
                                  widget.repository.markNotificationAsRead(notification.id);
                                  HapticFeedback.selectionClick();
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: notification.isRead
                                      ? AppColors.darkCard.withValues(alpha: 0.6)
                                      : AppColors.darkCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: notification.isRead
                                        ? AppColors.darkBorder
                                        : typeColor.withValues(alpha: 0.4),
                                    width: notification.isRead ? 1 : 1.5,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon Badge
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          notification.icon,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification.title,
                                                  style: TextStyle(
                                                    color: AppColors.darkTextPrimary,
                                                    fontSize: 14,
                                                    fontWeight: notification.isRead
                                                        ? FontWeight.w500
                                                        : FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (!notification.isRead) ...[
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: typeColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              Text(
                                                _formatTimeAgo(notification.createdAt),
                                                style: const TextStyle(
                                                  color: AppColors.darkTextTertiary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notification.message,
                                            style: const TextStyle(
                                              color: AppColors.darkTextSecondary,
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
