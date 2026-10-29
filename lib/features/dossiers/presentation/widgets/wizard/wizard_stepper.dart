import 'package:flutter/material.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/l10n/app_strings.dart';

class WizardStepper extends StatelessWidget {
  final int currentStep;
  final Color primaryColor;
  final bool isAvocat;

  const WizardStepper({
    super.key,
    required this.currentStep,
    required this.primaryColor,
    required this.isAvocat,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      isAvocat ? tr('Avocats') : tr('Psychologues'),
      tr('Informations'),
      tr('Pièces jointes'),
      tr('Validation'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < currentStep;
          final isActive = index == currentStep;

          Color getCircleColor() {
            if (isCompleted || isActive) return primaryColor;
            return context.palette.card;
          }

          Color getBorderColor() {
            if (isCompleted || isActive) return primaryColor;
            return context.palette.borderStrong;
          }

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index != 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted || isActive
                              ? primaryColor
                              : context.palette.borderStrong,
                        ),
                      )
                    else
                      const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: getCircleColor(),
                        border: Border.all(color: getBorderColor(), width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : context.palette.textSubtle,
                                ),
                              ),
                      ),
                    ),
                    if (index != steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? primaryColor
                              : context.palette.borderStrong,
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive || isCompleted
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: isActive || isCompleted
                        ? context.palette.textStrong
                        : context.palette.textSubtle,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
