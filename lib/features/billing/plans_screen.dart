import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import 'billing_controller.dart';
import 'store_gateway.dart';

/// Premium plans, for parents only (opened from the gated Parent Area).
/// Plain and honest: real store prices, no countdowns, no pressure.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(billingControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final billing = ref.watch(billingControllerProvider);
    final premium = ref.watch(entitlementProvider);
    final controller = ref.read(billingControllerProvider.notifier);

    final message = switch (billing.message) {
      BillingMessage.none => null,
      BillingMessage.thanks => l10n.premiumThanks,
      BillingMessage.restored => l10n.restoreDone,
      BillingMessage.nothingToRestore => l10n.restoreNone,
      BillingMessage.failed => l10n.purchaseFailed,
    };

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(l10n.plansTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          children: [
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(message, style: text.titleLarge),
              ),
            if (billing.pending) ...[
              const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(l10n.purchasePending),
              ),
            ],
            if (premium != null)
              ListTile(
                leading: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: AppSpacing.xl,
                ),
                title: Text(l10n.premiumActive, style: text.titleLarge),
              )
            else ...[
              Text(l10n.plansPitch, style: text.titleLarge),
              const SizedBox(height: AppSpacing.md),
              switch (billing.available) {
                null => const Center(child: CircularProgressIndicator()),
                false => Text(l10n.storeUnavailable),
                true => Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final plan in PremiumPlan.values)
                      _PlanCard(
                        plan: plan,
                        product: billing.products[plan],
                        onBuy: billing.pending
                            ? null
                            : () => controller.buy(plan),
                      ),
                  ],
                ),
              },
              const SizedBox(height: AppSpacing.md),
              Text(l10n.subscriptionTerms, style: text.bodySmall),
            ],
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.restore,
                icon: const Icon(Icons.restore_rounded),
                label: Text(l10n.restorePurchase),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.product,
    required this.onBuy,
  });

  final PremiumPlan plan;
  final StoreProduct? product;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final title = switch (plan) {
      PremiumPlan.monthly => l10n.planMonthly,
      PremiumPlan.yearly => l10n.planYearly,
      PremiumPlan.lifetime => l10n.planLifetime,
    };
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleLarge),
              Text(product?.price ?? '—', style: text.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                key: ValueKey('buy-${plan.name}'),
                onPressed: product == null ? null : onBuy,
                child: Text(l10n.buy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
