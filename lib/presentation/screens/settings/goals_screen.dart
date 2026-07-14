import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../data/models/goal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/notification_service.dart';
import '../../providers/storage_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/upgrade_dialog.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/common/banner_ad_widget.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeGoals = ref.watch(activeGoalsProvider);
    final completedGoals = ref.watch(completedGoalsProvider);
    final totalSaved = ref.watch(totalSavedInGoalsProvider);
    final totalTarget = ref.watch(totalGoalsTargetProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final limit = FreeTierLimits.goals;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.savingsGoals ?? 'Savings Goals'),
        actions: [
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activeGoals.length >= limit
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activeGoals.length}/$limit',
                    style: AppTypography.labelSmall.copyWith(
                      color: activeGoals.length >= limit
                          ? AppColors.warning
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: activeGoals.isEmpty && completedGoals.isEmpty
          ? _EmptyState(isDark: isDark, l10n: l10n, onAdd: () => _showAddGoalSheet(context, ref))
          : CustomScrollView(
              slivers: [
                // Summary Card
                if (activeGoals.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SummaryCard(
                      isDark: isDark,
                      l10n: l10n,
                      totalSaved: totalSaved,
                      totalTarget: totalTarget,
                      activeCount: activeGoals.length,
                    ),
                  ),

                // Active Goals Header
                if (activeGoals.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.spacing16,
                        AppDimensions.spacing8,
                        AppDimensions.spacing16,
                        AppDimensions.spacing12,
                      ),
                      child: Text(
                        l10n?.goalsActiveGoals ?? 'Active Goals',
                        style: AppTypography.h4.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ),

                // Active Goals List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final goal = activeGoals[index];
                      return _GoalCard(
                        goal: goal,
                        isDark: isDark,
                        l10n: l10n,
                        onTap: () => _showGoalDetails(context, goal),
                        onAddMoney: () => _showAddMoneySheet(context, ref, goal),
                      );
                    },
                    childCount: activeGoals.length,
                  ),
                ),

                // Completed Goals Section
                if (completedGoals.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.spacing16,
                        AppDimensions.spacing24,
                        AppDimensions.spacing16,
                        AppDimensions.spacing12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.trophy,
                            size: 20,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppDimensions.spacing8),
                          Text(
                            l10n?.goalsCompletedCount(completedGoals.length) ?? 'Completed (${completedGoals.length})',
                            style: AppTypography.h4.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final goal = completedGoals[index];
                        return _CompletedGoalCard(
                          goal: goal,
                          isDark: isDark,
                          l10n: l10n,
                          onTap: () => _showGoalDetails(context, goal),
                        );
                      },
                      childCount: completedGoals.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalSheet(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          l10n?.goalsNewGoal ?? 'New Goal',
          style: AppTypography.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    // Check premium limit
    final goals = ref.read(activeGoalsProvider);
    final canAdd = ref.read(subscriptionProvider.notifier).canAddMore(
      PremiumFeature.unlimitedGoals,
      goals.length,
    );

    if (!canAdd) {
      UpgradeDialog.show(
        context,
        feature: PremiumFeature.unlimitedGoals,
        currentCount: goals.length,
        limit: FreeTierLimits.goals,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddGoalSheet(),
    );
  }

  void _showGoalDetails(BuildContext context, SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoalDetailsSheet(goal: goal),
    );
  }

  void _showAddMoneySheet(BuildContext context, WidgetRef ref, SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMoneySheet(goal: goal),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final VoidCallback onAdd;

  const _EmptyState({required this.isDark, this.l10n, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.target,
              size: 80,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              l10n?.noGoalsYet ?? 'No savings goals yet',
              style: AppTypography.h3.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              l10n?.goalsEmptyStateDesc ?? 'Create your first goal to start\ntracking your savings progress',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacing24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n?.createGoal ?? 'Create Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final double totalSaved;
  final double totalTarget;
  final int activeCount;

  const _SummaryCard({
    required this.isDark,
    this.l10n,
    required this.totalSaved,
    required this.totalTarget,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalTarget > 0 ? (totalSaved / totalTarget) : 0.0;

    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacing16),
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.goalsTotalSaved ?? 'Total Saved',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalSaved),
                    style: AppTypography.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing12,
                  vertical: AppDimensions.spacing8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                ),
                child: Text(
                  l10n?.goalsActiveCount(activeCount) ?? '$activeCount active',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.goalsTargetAmount(CurrencyFormatter.format(totalTarget)) ?? 'Target: ${CurrencyFormatter.format(totalTarget)}',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final bool isDark;
  final AppLocalizations? l10n;
  final VoidCallback onTap;
  final VoidCallback onAddMoney;

  const _GoalCard({
    required this.goal,
    required this.isDark,
    this.l10n,
    required this.onTap,
    required this.onAddMoney,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercent / 100;
    final progressColor = goal.isOverdue
        ? AppColors.error
        : progress >= 0.8
            ? AppColors.success
            : progress >= 0.5
                ? AppColors.warning
                : AppColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: goal.isOverdue
              ? AppColors.error.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: goal.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Icon(
                        goal.icon,
                        color: goal.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${CurrencyFormatter.format(goal.currentAmount)} of ${CurrencyFormatter.format(goal.targetAmount)}',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${goal.progressPercent.toStringAsFixed(0)}%',
                          style: AppTypography.h4.copyWith(
                            color: progressColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (goal.daysRemaining != null)
                          Text(
                            goal.isOverdue
                                ? (l10n?.goalsOverdue ?? 'Overdue')
                                : (l10n?.goalsDaysLeft(goal.daysRemaining!) ?? '${goal.daysRemaining}d left'),
                            style: AppTypography.caption.copyWith(
                              color: goal.isOverdue
                                  ? AppColors.error
                                  : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing12),
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                              minHeight: 8,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    GestureDetector(
                      onTap: onAddMoney,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing12,
                          vertical: AppDimensions.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.plus,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n?.add ?? 'Add',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletedGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final bool isDark;
  final AppLocalizations? l10n;
  final VoidCallback onTap;

  const _CompletedGoalCard({
    required this.goal,
    required this.isDark,
    this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Icon(
                    LucideIcons.checkCircle,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${l10n?.goalsCompletedLabel ?? 'Completed'} ${goal.completedAt != null ? DateFormat('dd MMM yyyy').format(goal.completedAt!) : ''}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(goal.targetAmount),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddGoalSheet extends ConsumerStatefulWidget {
  final SavingsGoal? existingGoal;

  const _AddGoalSheet({this.existingGoal});

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _targetDate;
  int _selectedPresetIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      _nameController.text = widget.existingGoal!.name;
      _amountController.text = widget.existingGoal!.targetAmount.toStringAsFixed(0);
      _targetDate = widget.existingGoal!.targetDate;
      // Find preset index by matching icon
      for (int i = 0; i < GoalPresets.options.length; i++) {
        if (GoalPresets.options[i].icon.codePoint == widget.existingGoal!.icon.codePoint) {
          _selectedPresetIndex = i;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingGoal != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.bottomSheetRadius),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),

              Text(
                isEditing ? (l10n?.editGoal ?? 'Edit Goal') : (l10n?.goalsCreateNewGoal ?? 'Create New Goal'),
                style: AppTypography.h3.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),

              // Goal Name
              Text(
                l10n?.goalName ?? 'Goal Name',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: l10n?.goalsNameHint ?? 'e.g., Emergency Fund, New Car',
                ),
              ),
              const SizedBox(height: AppDimensions.spacing20),

              // Target Amount
              Text(
                l10n?.targetAmount ?? 'Target Amount',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: '\u20B9 ',
                  hintText: l10n?.goalsEnterTargetAmount ?? 'Enter target amount',
                ),
              ),
              const SizedBox(height: AppDimensions.spacing20),

              // Target Date (Optional)
              Text(
                l10n?.goalsTargetDateOptional ?? 'Target Date (Optional)',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() => _targetDate = date);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spacing16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 20,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: AppDimensions.spacing12),
                      Text(
                        _targetDate != null
                            ? DateFormat('dd MMM yyyy').format(_targetDate!)
                            : (l10n?.goalsNoDeadlineSet ?? 'No deadline set'),
                        style: AppTypography.bodyMedium.copyWith(
                          color: _targetDate != null
                              ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                              : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                        ),
                      ),
                      const Spacer(),
                      if (_targetDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _targetDate = null),
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing20),

              // Icon & Color Selection
              Text(
                l10n?.chooseIcon ?? 'Choose Icon',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              Wrap(
                spacing: AppDimensions.spacing8,
                runSpacing: AppDimensions.spacing8,
                children: List.generate(GoalPresets.options.length, (index) {
                  final preset = GoalPresets.options[index];
                  final isSelected = _selectedPresetIndex == index;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedPresetIndex = index),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? preset.color.withValues(alpha: 0.2)
                            : (isDark ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: isSelected
                              ? preset.color
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        preset.icon,
                        color: isSelected
                            ? preset.color
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        size: 24,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppDimensions.spacing24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveGoal,
                  child: Text(_isSaving
                      ? (l10n?.saving ?? 'Saving...')
                      : (isEditing ? (l10n?.goalsUpdateGoal ?? 'Update Goal') : (l10n?.createGoal ?? 'Create Goal'))),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveGoal() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.goalsPleaseEnterGoalName ?? 'Please enter a goal name')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.goalsPleaseEnterValidTargetAmount ?? 'Please enter a valid target amount')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final preset = GoalPresets.options[_selectedPresetIndex];
    final now = DateTime.now();

    if (widget.existingGoal != null) {
      final updatedGoal = widget.existingGoal!.copyWith(
        name: name,
        targetAmount: amount,
        targetDate: _targetDate,
        icon: preset.icon,
        color: preset.color,
        updatedAt: now,
      );
      await ref.read(goalsProvider.notifier).updateGoal(updatedGoal);
    } else {
      final newGoal = SavingsGoal(
        id: 'goal_${now.millisecondsSinceEpoch}',
        name: name,
        targetAmount: amount,
        targetDate: _targetDate,
        icon: preset.icon,
        color: preset.color,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(goalsProvider.notifier).addGoal(newGoal);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingGoal != null ? (l10n?.goalUpdated ?? 'Goal updated') : (l10n?.goalCreated ?? 'Goal created')),
        ),
      );
    }
  }
}

class _AddMoneySheet extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const _AddMoneySheet({required this.goal});

  @override
  ConsumerState<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends ConsumerState<_AddMoneySheet> {
  final _amountController = TextEditingController();
  bool _isWithdraw = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.bottomSheetRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // Goal Info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.goal.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Icon(
                    widget.goal.icon,
                    color: widget.goal.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.goal.name,
                        style: AppTypography.h4.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        l10n?.goalsAmountSaved(CurrencyFormatter.format(widget.goal.currentAmount)) ?? '${CurrencyFormatter.format(widget.goal.currentAmount)} saved',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // Add/Withdraw Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isWithdraw = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
                      decoration: BoxDecoration(
                        color: !_isWithdraw
                            ? AppColors.success.withValues(alpha: 0.1)
                            : (isDark ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: !_isWithdraw
                              ? AppColors.success
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 18,
                            color: !_isWithdraw
                                ? AppColors.success
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n?.addMoney ?? 'Add Money',
                            style: AppTypography.labelMedium.copyWith(
                              color: !_isWithdraw
                                  ? AppColors.success
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isWithdraw = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
                      decoration: BoxDecoration(
                        color: _isWithdraw
                            ? AppColors.error.withValues(alpha: 0.1)
                            : (isDark ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: _isWithdraw
                              ? AppColors.error
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.minus,
                            size: 18,
                            color: _isWithdraw
                                ? AppColors.error
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n?.goalsWithdraw ?? 'Withdraw',
                            style: AppTypography.labelMedium.copyWith(
                              color: _isWithdraw
                                  ? AppColors.error
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing20),

            // Amount Input
            Text(
              l10n?.amount ?? 'Amount',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: '\u20B9 ',
                hintText: _isWithdraw
                    ? (l10n?.goalsAmountToWithdraw ?? 'Amount to withdraw')
                    : (l10n?.goalsAmountToAdd ?? 'Amount to add'),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),

            // Quick amounts
            Wrap(
              spacing: AppDimensions.spacing8,
              runSpacing: AppDimensions.spacing8,
              children: [500, 1000, 2000, 5000, 10000].map((amount) {
                return GestureDetector(
                  onTap: () => _amountController.text = amount.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing12,
                      vertical: AppDimensions.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: (_isWithdraw ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(
                        color: (_isWithdraw ? AppColors.error : AppColors.success).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '\u20B9${amount >= 1000 ? '${amount ~/ 1000}K' : amount}',
                      style: AppTypography.labelSmall.copyWith(
                        color: _isWithdraw ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isWithdraw ? AppColors.error : AppColors.success,
                ),
                child: Text(_isSaving
                    ? (l10n?.processing ?? 'Processing...')
                    : (_isWithdraw ? (l10n?.goalsWithdraw ?? 'Withdraw') : (l10n?.addMoney ?? 'Add Money'))),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.pleaseEnterValidAmount ?? 'Please enter a valid amount')),
      );
      return;
    }

    if (_isWithdraw && amount > widget.goal.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.goalsCannotWithdrawMoreThanSaved ?? 'Cannot withdraw more than saved amount')),
      );
      return;
    }

    setState(() => _isSaving = true);

    SavingsGoal? updatedGoal;
    if (_isWithdraw) {
      updatedGoal = await ref.read(goalsProvider.notifier).withdrawFromGoal(widget.goal.id, amount);
    } else {
      updatedGoal = await ref.read(goalsProvider.notifier).addToGoal(widget.goal.id, amount);
    }

    // Send goal progress notification
    if (updatedGoal != null && !_isWithdraw) {
      await _checkGoalProgressAndNotify(widget.goal, updatedGoal);
    }

    if (mounted) {
      Navigator.pop(context);

      final amountFormatted = '\u20B9${amount.toStringAsFixed(0)}';
      String message = _isWithdraw
          ? (l10n?.goalsWithdrawnAmount(amountFormatted) ?? 'Withdrawn $amountFormatted')
          : (l10n?.goalsAddedAmount(amountFormatted) ?? 'Added $amountFormatted');

      // Check if goal was just completed
      if (updatedGoal != null && updatedGoal.isCompleted && !widget.goal.isCompleted) {
        message = l10n?.goalsCompletedMessage(widget.goal.name) ?? 'Goal completed! ${widget.goal.name}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Check goal progress and send milestone notifications
  Future<void> _checkGoalProgressAndNotify(SavingsGoal oldGoal, SavingsGoal newGoal) async {
    try {
      final oldPercent = ((oldGoal.currentAmount / oldGoal.targetAmount) * 100).round();
      final newPercent = ((newGoal.currentAmount / newGoal.targetAmount) * 100).round();

      // Check for completion
      if (newGoal.isCompleted && !oldGoal.isCompleted) {
        await NotificationService.instance.showGoalProgress(
          goalName: newGoal.name,
          percentComplete: 100,
          currentAmount: newGoal.currentAmount,
          targetAmount: newGoal.targetAmount,
          isMilestone: true,
        );
        return;
      }

      // Check for milestone crossings (25%, 50%, 75%)
      final milestones = [25, 50, 75];
      for (final milestone in milestones) {
        if (oldPercent < milestone && newPercent >= milestone) {
          await NotificationService.instance.showGoalProgress(
            goalName: newGoal.name,
            percentComplete: newPercent,
            currentAmount: newGoal.currentAmount,
            targetAmount: newGoal.targetAmount,
            isMilestone: true,
          );
          break; // Only send one milestone notification at a time
        }
      }
    } catch (e) {
      debugPrint('Error sending goal progress notification: $e');
    }
  }
}

class _GoalDetailsSheet extends ConsumerWidget {
  final SavingsGoal goal;

  const _GoalDetailsSheet({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Icon(
                    goal.icon,
                    color: goal.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: AppTypography.h3.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (goal.isCompleted)
                        Row(
                          children: [
                            Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              l10n?.goalsCompletedLabel ?? 'Completed',
                              style: AppTypography.caption.copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    LucideIcons.x,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
              child: Column(
                children: [
                  // Progress Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spacing20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          goal.color.withValues(alpha: 0.15),
                          goal.color.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                      border: Border.all(
                        color: goal.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${goal.progressPercent.toStringAsFixed(1)}%',
                          style: AppTypography.h1.copyWith(
                            color: goal.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing8),
                        Text(
                          '${CurrencyFormatter.format(goal.currentAmount)} of ${CurrencyFormatter.format(goal.targetAmount)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing16),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: (goal.progressPercent / 100).clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: goal.color.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                                minHeight: 10,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        Text(
                          l10n?.goalsAmountRemaining(CurrencyFormatter.format(goal.remainingAmount)) ?? '${CurrencyFormatter.format(goal.remainingAmount)} remaining',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacing20),

                  // Details
                  if (goal.targetDate != null)
                    _DetailTile(
                      icon: LucideIcons.calendar,
                      label: l10n?.targetDate ?? 'Target Date',
                      value: DateFormat('dd MMM yyyy').format(goal.targetDate!),
                      trailing: goal.isOverdue
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n?.goalsOverdue ?? 'Overdue',
                                style: AppTypography.caption.copyWith(color: AppColors.error),
                              ),
                            )
                          : Text(
                              l10n?.goalsDaysLeftLong(goal.daysRemaining ?? 0) ?? '${goal.daysRemaining} days left',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                      isDark: isDark,
                    ),

                  _DetailTile(
                    icon: LucideIcons.clock,
                    label: l10n?.goalsCreated ?? 'Created',
                    value: DateFormat('dd MMM yyyy').format(goal.createdAt),
                    isDark: isDark,
                  ),

                  if (goal.milestonesReached.isNotEmpty)
                    _DetailTile(
                      icon: LucideIcons.award,
                      label: l10n?.goalsMilestones ?? 'Milestones',
                      value: goal.milestonesReached.map((m) => '$m%').join(', '),
                      isDark: isDark,
                    ),

                  const SizedBox(height: AppDimensions.spacing24),

                  // Action Buttons
                  if (!goal.isCompleted)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => _AddGoalSheet(existingGoal: goal),
                              );
                            },
                            icon: const Icon(LucideIcons.pencil, size: 18),
                            label: Text(l10n?.edit ?? 'Edit'),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacing12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => _AddMoneySheet(goal: goal),
                              );
                            },
                            icon: const Icon(LucideIcons.plus, size: 18),
                            label: Text(l10n?.addMoney ?? 'Add Money'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppDimensions.spacing12),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n?.deleteGoalQuestion ?? 'Delete Goal?'),
                            content: Text(l10n?.goalsDeleteConfirmation(goal.name) ?? 'Are you sure you want to delete "${goal.name}"? This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l10n?.cancel ?? 'Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n?.goalDeleted ?? 'Goal deleted')),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      label: Text(l10n?.deleteGoal ?? 'Delete Goal'),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final bool isDark;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
