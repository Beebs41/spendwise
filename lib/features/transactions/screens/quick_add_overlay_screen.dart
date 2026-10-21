import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/widget_sync_service.dart';
import '../../../data/repositories/transaction_repository.dart';
import 'add_transaction_sheet.dart';

/// Full-screen translucent overlay designed to be launched directly over
/// the Android Home Screen from the SpendWise AppWidget.
class QuickAddOverlayScreen extends StatelessWidget {
  final TransactionRepository repository;

  const QuickAddOverlayScreen({super.key, required this.repository});

  void _closeOverlay() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _closeOverlay();
      },
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Dismissible barrier area above the sheet
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeOverlay,
                  child: const SizedBox.expand(),
                ),
              ),

              // The sheet itself
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.90,
                    ),
                    child: AddTransactionSheet(
                      repository: repository,
                      onAdded: () {
                        // Immediately synchronize widget metrics so home screen updates live
                        WidgetSyncService.syncWidget(repository);
                        Future.delayed(const Duration(milliseconds: 250), _closeOverlay);
                      },
                      onDeleted: _closeOverlay,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
