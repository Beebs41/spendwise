import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';

class ReceiptViewerDialog extends StatelessWidget {
  final String imagePath;
  final String? title;
  final String? subtitle;

  const ReceiptViewerDialog({
    super.key,
    required this.imagePath,
    this.title,
    this.subtitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String imagePath,
    String? title,
    String? subtitle,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => ReceiptViewerDialog(
        imagePath: imagePath,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    HapticFeedback.lightImpact();
    final file = File(imagePath);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt image file not found')),
        );
      }
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              name: file.uri.pathSegments.last,
            ),
          ],
          subject: title ?? 'SpendWise Receipt',
          text: subtitle != null ? 'Receipt: $subtitle' : null,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share receipt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final fileExists = file.existsSync();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SafeArea(
        child: Stack(
          children: [
            // Center Image viewer
            Center(
              child: fileExists
                  ? InteractiveViewer(
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 70),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            file,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => _buildErrorState(),
                          ),
                        ),
                      ),
                    )
                  : _buildErrorState(),
            ),

            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title ?? 'Receipt Photo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (fileExists) ...[
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white),
                        onPressed: () => _shareReceipt(context),
                        tooltip: 'Share Receipt',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom hint bar
            if (fileExists)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pinch_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pinch or drag to zoom',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppColors.darkDanger,
          ),
          const SizedBox(height: 16),
          const Text(
            'Receipt File Not Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The receipt image could not be loaded from storage:\n$imagePath',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
