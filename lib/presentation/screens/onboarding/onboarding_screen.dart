import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/storage/storage_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> _buildPages(AppLocalizations? l10n) {
    return [
      OnboardingPage(
        icon: LucideIcons.wallet,
        title: l10n?.onboardingTitle1 ?? 'Track Every Income Stream',
        description: l10n?.onboardingDesc1 ?? 'Salary, freelance, business, passive income. Manage all your earnings in one place.',
        color: AppColors.success,
      ),
      OnboardingPage(
        icon: LucideIcons.pieChart,
        title: l10n?.onboardingTitle2 ?? 'Know Where Money Goes',
        description: l10n?.onboardingDesc2 ?? 'Categorize expenses, scan receipts and see spending patterns at a glance.',
        color: AppColors.primary,
      ),
      OnboardingPage(
        icon: LucideIcons.searchX,
        title: l10n?.onboardingTitle3 ?? 'Find Your Money Leaks',
        description: l10n?.onboardingDesc3 ?? 'AI detects wasteful spending you don\'t notice. Small purchases that add up.',
        color: AppColors.warning,
      ),
      OnboardingPage(
        icon: LucideIcons.sparkles,
        title: l10n?.onboardingTitle4 ?? 'Ready to Take Control?',
        description: l10n?.onboardingDesc4 ?? 'Start tracking your finances today and never wonder where your money went again.',
        color: AppColors.primary,
        isLastPage: true,
      ),
    ];
  }

  void _nextPage(int pagesLength) {
    if (_currentPage < pagesLength - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    // Save onboarding completed flag
    await StorageService.instance.saveSetting('onboarding_completed', true);
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final pages = _buildPages(l10n);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    l10n?.skip ?? 'Skip',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageWidget(
                    page: pages[index],
                    isDark: isDark,
                    pageIndex: index,
                  );
                },
              ),
            ),

            // Page Indicator
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacing24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => _PageIndicator(
                    isActive: index == _currentPage,
                    isDark: isDark,
                  ),
                ),
              ),
            ),

            // Next/Get Started Button
            Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _nextPage(pages.length),
                  style: _currentPage == pages.length - 1
                      ? ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        )
                      : null,
                  child: Text(
                    _currentPage == pages.length - 1
                        ? (l10n?.yesLetsGo ?? "Yes, Let's Go!")
                        : (l10n?.next ?? 'Next'),
                    style: _currentPage == pages.length - 1
                        ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.spacing16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isLastPage;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isLastPage = false,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final bool isDark;
  final int pageIndex;

  const _OnboardingPageWidget({
    required this.page,
    required this.isDark,
    required this.pageIndex,
  });

  Widget _buildAnimatedIcon() {
    final iconWidget = Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: page.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        page.icon,
        size: 64,
        color: page.color,
      ),
    );

    // Different animations for each page
    switch (pageIndex) {
      case 0: // Wallet - gentle pulse animation
        return iconWidget
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.08, 1.08),
              duration: 1500.ms,
              curve: Curves.easeInOut,
            );
      case 1: // PieChart - slow rotation
        return iconWidget
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(
              begin: 0,
              end: 0.02,
              duration: 2000.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .rotate(
              begin: 0.02,
              end: -0.02,
              duration: 2000.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .rotate(
              begin: -0.02,
              end: 0,
              duration: 2000.ms,
              curve: Curves.easeInOut,
            );
      case 2: // SearchX - shake/wiggle animation for finding leaks
        return iconWidget
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveX(
              begin: 0,
              end: 4,
              duration: 400.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .moveX(
              begin: 4,
              end: -4,
              duration: 400.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .moveX(
              begin: -4,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeInOut,
            );
      case 3: // Sparkles - shimmer effect
        return iconWidget
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .shimmer(
              duration: 1800.ms,
              color: page.color.withValues(alpha: 0.3),
            )
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: 1200.ms,
              curve: Curves.easeInOut,
            );
      default:
        return iconWidget;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal * 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon Container
          _buildAnimatedIcon(),

          const SizedBox(height: AppDimensions.spacing48),

          // Title with fade in animation
          Text(
            page.title,
            style: AppTypography.h2.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms),

          const SizedBox(height: AppDimensions.spacing16),

          // Description with fade in animation
          Text(
            page.description,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 400.ms),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;
  final bool isDark;

  const _PageIndicator({
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
