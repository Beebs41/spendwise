import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../features/notifications/screens/notifications_sheet.dart';

class NotificationBellButton extends StatelessWidget {
  final TransactionRepository repository;

  const NotificationBellButton({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: repository.watchUnreadNotificationCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.darkTextPrimary, size: 24),
              tooltip: 'Notifications',
              onPressed: () {
                NotificationsSheet.show(context, repository: repository);
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.darkDanger,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkBackground, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkDanger.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
