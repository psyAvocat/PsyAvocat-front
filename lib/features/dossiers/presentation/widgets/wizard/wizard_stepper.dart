import 'package:flutter/material.dart';

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
      isAvocat ? 'Avocats' : 'Psychologues',
      'Informations',
      'Pièces jointes',
      'Validation',
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
            return Colors.white;
          }

          Color getBorderColor() {
            if (isCompleted || isActive) return primaryColor;
            return const Color(0xFFD1D5DB);
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
                              : const Color(0xFFD1D5DB),
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
                                      : const Color(0xFF9CA3AF),
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
                              : const Color(0xFFD1D5DB),
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
                        ? const Color(0xFF111827)
                        : const Color(0xFF9CA3AF),
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
