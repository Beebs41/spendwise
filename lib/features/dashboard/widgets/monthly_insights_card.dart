import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/database/app_database.dart';

class MonthlyInsightsCard extends StatefulWidget {
  final List<TransactionWithCategory> currentTransactions;
  final List<TransactionWithCategory> previousTransactions;
  final List<BudgetWithCategory> budgets;
  final DateTime currentDate;
  final VoidCallback? onExploreDetails;

  const MonthlyInsightsCard({
    super.key,
    required this.currentTransactions,
    required this.previousTransactions,
    this.budgets = const [],
    required this.currentDate,
    this.onExploreDetails,
  });

  @override
  State<MonthlyInsightsCard> createState() => _MonthlyInsightsCardState();
}

class _MonthlyInsightsCardState extends State<MonthlyInsightsCard> {
  int _activeTab = 0; // 0: Overview, 1: Daily Trend

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Calculate Expenses & Incomes
    final currentExpenses = widget.currentTransactions
        .where((t) => t.transaction.type == 'expense')
        .toList();
    final currentIncomes = widget.currentTransactions
        .where((t) => t.transaction.type == 'income')
        .toList();

    final currentTotalExpense = currentExpenses.fold<double>(
      0.0,
      (sum, t) => sum + t.transaction.amount,
    );
    final currentTotalIncome = currentIncomes.fold<double>(
      0.0,
      (sum, t) => sum + t.transaction.amount,
    );

    final previousTotalExpense = widget.previousTransactions
        .where((t) => t.transaction.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.transaction.amount);

    // 2. Month-over-Month Comparison
    final diffExpense = currentTotalExpense - previousTotalExpense;
    final hasPrevData = previousTotalExpense > 0;
    final percentChange = hasPrevData
        ? ((diffExpense.abs() / previousTotalExpense) * 100)
        : 0.0;

    // 3. Top Category
    final Map<int, ({String name, String icon, int color, double amount})> categoryMap = {};
    for (final t in currentExpenses) {
      final catId = t.category.id;
      final existing = categoryMap[catId];
      if (existing != null) {
        categoryMap[catId] = (
          name: existing.name,
          icon: existing.icon,
          color: existing.color,
          amount: existing.amount + t.transaction.amount,
        );
      } else {
        categoryMap[catId] = (
          name: t.category.name,
          icon: t.category.icon,
          color: t.category.color,
          amount: t.transaction.amount,
        );
      }
    }

    final sortedCategories = categoryMap.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topCategory = sortedCategories.isNotEmpty ? sortedCategories.first : null;
    final topCategoryPercent = (topCategory != null && currentTotalExpense > 0)
        ? (topCategory.amount / currentTotalExpense) * 100
        : 0.0;

    // 4. Daily Spending Average
    final daysInCurrentMonth = DateTime(widget.currentDate.year, widget.currentDate.month + 1, 0).day;
    final dayOfMonth = widget.currentDate.day.clamp(1, daysInCurrentMonth);
    final dailyAverage = currentTotalExpense / dayOfMonth;

    // 5. Daily Spending Map for Sparkline
    final Map<int, double> dailyExpenses = {};
    for (int i = 1; i <= dayOfMonth; i++) {
      dailyExpenses[i] = 0.0;
    }
    for (final t in currentExpenses) {
      final day = t.transaction.date.day;
      if (day <= dayOfMonth) {
        dailyExpenses[day] = (dailyExpenses[day] ?? 0.0) + t.transaction.amount;
      }
    }

    // 6. Savings Rate
    final netSavings = currentTotalIncome - currentTotalExpense;
    final savingsRate = currentTotalIncome > 0
        ? ((netSavings / currentTotalIncome) * 100).clamp(0.0, 100.0)
        : 0.0;

    // 7. Total Budget Burn Pace
    final totalBudget = widget.budgets.fold<double>(0.0, (sum, b) => sum + b.budget.amount);
    final hasBudget = totalBudget > 0;
    final budgetUsedPercent = hasBudget ? (currentTotalExpense / totalBudget) * 100 : 0.0;
    final daysRemaining = math.max(0, daysInCurrentMonth - dayOfMonth);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.25),
                            (isDark ? AppColors.darkAccent : AppColors.lightAccent).withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FINANCIAL INTELLIGENCE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Monthly Insights & Trends',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // View Mode Segment Tabs
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      _SegmentTab(
                        label: 'Overview',
                        isSelected: _activeTab == 0,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeTab = 0);
                        },
                      ),
                      _SegmentTab(
                        label: 'Trend',
                        isSelected: _activeTab == 1,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeTab = 1);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Content body based on active tab
          if (_activeTab == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MoM Comparison Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (!hasPrevData
                              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                              : diffExpense > 0
                                  ? AppColors.darkDanger
                                  : AppColors.darkSuccess)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (!hasPrevData
                                ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                                : diffExpense > 0
                                    ? AppColors.darkDanger
                                    : AppColors.darkSuccess)
                            .withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          !hasPrevData
                              ? Icons.info_outline_rounded
                              : diffExpense > 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                          size: 20,
                          color: !hasPrevData
                              ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                              : diffExpense > 0
                                  ? AppColors.darkDanger
                                  : AppColors.darkSuccess,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            !hasPrevData
                                ? 'First recorded month! Keep tracking to unlock month-over-month comparisons.'
                                : diffExpense > 0
                                    ? 'You spent ${percentChange.toStringAsFixed(0)}% more (${CurrencyFormatter.formatCompact(diffExpense)}) than last month.'
                                    : 'Awesome! You spent ${percentChange.toStringAsFixed(0)}% less (${CurrencyFormatter.formatCompact(diffExpense.abs())}) than last month.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2-Column Quick Metrics
                  Row(
                    children: [
                      // Daily Average
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DAILY AVERAGE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${CurrencyFormatter.formatCompact(dailyAverage)}/day',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Over $dayOfMonth days',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Savings Rate / Velocity
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasBudget ? 'BUDGET USED' : 'SAVINGS RATE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasBudget
                                    ? '${budgetUsedPercent.toStringAsFixed(0)}%'
                                    : '${savingsRate.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: hasBudget
                                      ? (budgetUsedPercent > 100
                                          ? AppColors.darkDanger
                                          : budgetUsedPercent > 80
                                              ? AppColors.darkWarning
                                              : AppColors.darkSuccess)
                                      : AppColors.darkSuccess,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasBudget
                                    ? '$daysRemaining days remaining'
                                    : (netSavings >= 0 ? '${CurrencyFormatter.formatCompact(netSavings)} saved' : 'Deficit'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Top Category Breakdown bar
                  if (topCategory != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(topCategory.icon, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Top Category: ${topCategory.name}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${CurrencyFormatter.formatCompact(topCategory.amount)} (${topCategoryPercent.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(topCategory.color),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (topCategoryPercent / 100).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(topCategory.color)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            // Daily Trend Sparkline Tab
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DAILY SPENDING TREND',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                        Text(
                          'Day 1 to $dayOfMonth',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Custom Sparkline Chart
                    SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: _DailySparkline(
                        dailyExpenses: dailyExpenses,
                        daysCount: dayOfMonth,
                        lineColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Day 1',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                        Text(
                          'Peak Day: Day ${_getPeakDay(dailyExpenses)} (${CurrencyFormatter.formatCompact(_getPeakAmount(dailyExpenses))})',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          ),
                        ),
                        Text(
                          'Day $dayOfMonth',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  int _getPeakDay(Map<int, double> map) {
    if (map.isEmpty) return 1;
    int peakDay = 1;
    double maxVal = -1;
    map.forEach((day, val) {
      if (val > maxVal) {
        maxVal = val;
        peakDay = day;
      }
    });
    return peakDay;
  }

  double _getPeakAmount(Map<int, double> map) {
    if (map.isEmpty) return 0.0;
    return map.values.fold(0.0, (max, val) => math.max(max, val));
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.black
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

class _DailySparkline extends StatelessWidget {
  final Map<int, double> dailyExpenses;
  final int daysCount;
  final Color lineColor;
  final bool isDark;

  const _DailySparkline({
    required this.dailyExpenses,
    required this.daysCount,
    required this.lineColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        data: dailyExpenses,
        daysCount: daysCount,
        lineColor: lineColor,
        isDark: isDark,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Map<int, double> data;
  final int daysCount;
  final Color lineColor;
  final bool isDark;

  _SparklinePainter({
    required this.data,
    required this.daysCount,
    required this.lineColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (daysCount <= 0 || data.isEmpty) return;

    final maxVal = data.values.fold<double>(0.0, (m, v) => math.max(m, v));
    final effectiveMax = maxVal > 0 ? maxVal * 1.15 : 100.0;

    // Draw grid guide lines
    final gridPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), gridPaint);

    final points = <Offset>[];
    final stepX = daysCount > 1 ? size.width / (daysCount - 1) : size.width;

    for (int day = 1; day <= daysCount; day++) {
      final val = data[day] ?? 0.0;
      final x = daysCount > 1 ? (day - 1) * stepX : size.width / 2;
      final normalizedY = (val / effectiveMax).clamp(0.0, 1.0);
      final y = size.height - (normalizedY * (size.height - 10)) - 5;
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Build smooth curve path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Gradient fill path under curve
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withValues(alpha: 0.35),
          lineColor.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Draw highlight point on the latest day
    final lastPoint = points.last;
    final dotPaint = Paint()..color = lineColor;
    final dotOuter = Paint()
      ..color = isDark ? AppColors.darkCard : AppColors.lightCard
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(lastPoint, 4.5, dotPaint);
    canvas.drawCircle(lastPoint, 4.5, dotOuter);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.daysCount != daysCount ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.isDark != isDark;
  }
}
