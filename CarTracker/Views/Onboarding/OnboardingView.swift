//
//  OnboardingView.swift
//  CarTracker
//

import SwiftUI
import SwiftData

// MARK: - Onboarding Step Enum

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case socialProof
    case carUsage
    case expenseWorries
    case currency
    case units
    case valueSavings
    case valueResale
    case valueMaintenance
    case calculating
    case savingsPlan
    case notifications
    case setupCar
    case allSet

    var hidesProgress: Bool {
        switch self {
        case .welcome, .calculating, .savingsPlan, .allSet:
            return true
        default:
            return false
        }
    }

    var hidesBackButton: Bool {
        switch self {
        case .welcome, .calculating, .savingsPlan, .allSet:
            return true
        default:
            return false
        }
    }

    static var progressSteps: Int {
        // Count only steps that show the progress bar
        allCases.filter { !$0.hidesProgress }.count
    }

    var progressValue: Int {
        let visibleSteps = OnboardingStep.allCases.filter { !$0.hidesProgress }
        guard let index = visibleSteps.firstIndex(of: self) else { return 0 }
        return index + 1
    }
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentStep: OnboardingStep = .welcome
    @State private var isNavigatingBack = false
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: back button + progress
            if !currentStep.hidesProgress {
                HStack(spacing: OnboardingDesign.Spacing.md) {
                    if !currentStep.hidesBackButton {
                        OnboardingBackButton { goToPrevious() }
                    }

                    OnboardingProgressBar(
                        currentStep: currentStep.progressValue,
                        totalSteps: OnboardingStep.progressSteps
                    )
                }
                .padding(.horizontal, OnboardingDesign.Spacing.lg)
                .padding(.vertical, OnboardingDesign.Spacing.sm)
            }

            // Step content with animated transitions
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeStepView { goToNext() }

                case .socialProof:
                    SocialProofStepView { goToNext() }

                case .carUsage:
                    CarUsageStepView(viewModel: viewModel) { goToNext() }

                case .expenseWorries:
                    ExpenseWorryStepView(viewModel: viewModel) { goToNext() }

                case .currency:
                    CurrencyStepView(viewModel: viewModel) { goToNext() }

                case .units:
                    UnitsStepView(viewModel: viewModel) { goToNext() }

                case .valueSavings:
                    ValueSavingsStepView(viewModel: viewModel) { goToNext() }

                case .valueResale:
                    ValueResaleStepView(viewModel: viewModel) { goToNext() }

                case .valueMaintenance:
                    ValueMaintenanceStepView(viewModel: viewModel) { goToNext() }

                case .calculating:
                    CalculatingStepView {
                        viewModel.applySettings()
                        goToNext()
                    }

                case .savingsPlan:
                    SavingsPlanStepView(viewModel: viewModel) { goToNext() }

                case .notifications:
                    NotificationsStepView { goToNext() }

                case .setupCar:
                    SetupCarStepView { goToNext() }

                case .allSet:
                    AllSetStepView { completeOnboarding() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OnboardingDesign.Colors.background)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(x: isNavigatingBack ? -50 : 50)),
                removal: .opacity.combined(with: .offset(x: isNavigatingBack ? 50 : -50))
            ))
            .id(currentStep)
        }
        .background(OnboardingDesign.Colors.background)
    }

    // MARK: - Navigation

    private func goToNext() {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex + 1 < allSteps.count else {
            completeOnboarding()
            return
        }
        isNavigatingBack = false
        withAnimation(OnboardingDesign.Animation.stepTransition) {
            currentStep = allSteps[currentIndex + 1]
        }
    }

    private func goToPrevious() {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        isNavigatingBack = true
        withAnimation(OnboardingDesign.Animation.stepTransition) {
            currentStep = allSteps[currentIndex - 1]
        }
    }

    private func completeOnboarding() {
        onComplete()
    }
}

// MARK: - Onboarding Manager

@Observable
class OnboardingManager {
    static let shared = OnboardingManager()

    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey) }
    }

    private init() {}

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    #if DEBUG
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
    #endif
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
    .modelContainer(for: [Car.self], inMemory: true)
    .environment(AppState())
}
