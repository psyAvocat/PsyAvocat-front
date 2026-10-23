import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/create_dossier_wizard_controller.dart';
import '../widgets/wizard/wizard_stepper.dart';
import '../widgets/wizard/step_avocats.dart';
import '../widgets/wizard/step_informations.dart';
import '../widgets/wizard/step_pieces_jointes.dart';
import '../widgets/wizard/step_validation.dart';
import '../widgets/wizard/step_confirmation.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Assistant d'envoi d'un dossier juridique (univers Avocat) :
/// avocats → informations → pièces jointes → validation et envoi réel.
class CreateDossierWizardScreen extends ConsumerStatefulWidget {
  const CreateDossierWizardScreen({super.key});

  @override
  ConsumerState<CreateDossierWizardScreen> createState() =>
      _CreateDossierWizardScreenState();
}

class _CreateDossierWizardScreenState
    extends ConsumerState<CreateDossierWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// « Modifier » depuis le récapitulatif : retour direct à l'étape concernée.
  void _allerA(int etape) {
    if (ref.read(createDossierWizardProvider).envoiEnCours) return;
    _pageController.animateToPage(
      etape,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (ref.read(createDossierWizardProvider).envoiEnCours) return;
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showConfirmation(Color primaryColor) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StepConfirmationScreen(primaryColor: primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previousStep();
      },
      child: Scaffold(
        backgroundColor: context.palette.page,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: AppBackButton(onPressed: _previousStep),
          title: Text(tr('Envoyer mon dossier')),
        ),
        body: SafeArea(
          child: Column(
            children: [
              WizardStepper(
                currentStep: _currentStep,
                primaryColor: primaryColor,
                isAvocat: true,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (idx) => setState(() => _currentStep = idx),
                  children: [
                    StepAvocats(onNext: _nextStep, primaryColor: primaryColor),
                    StepInformations(
                      onNext: _nextStep,
                      onBack: _previousStep,
                      primaryColor: primaryColor,
                    ),
                    StepPiecesJointes(
                      onNext: _nextStep,
                      onBack: _previousStep,
                      primaryColor: primaryColor,
                    ),
                    StepValidation(
                      onSubmitted: () => _showConfirmation(primaryColor),
                      onBack: _previousStep,
                      onModifier: _allerA,
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
