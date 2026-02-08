//
//  CalculatingStepView.swift
//  CarTracker
//

import SwiftUI

struct CalculatingStepView: View {
    let onComplete: () -> Void

    @State private var progress: Double = 0
    @State private var currentMessageIndex = 0
    @State private var appeared = false

    private let messages = [
        "Analyzing your driving profile...",
        "Calculating potential savings...",
        "Estimating resale value boost...",
        "Building your personalized plan...",
        "Almost ready...",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: OnboardingDesign.Spacing.xxl) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(OnboardingDesign.Colors.progressBackground, lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            OnboardingDesign.Colors.accent,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                            .contentTransition(.numericText())

                        Image(systemName: "car.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(OnboardingDesign.Colors.accent)
                    }
                }
                .frame(width: 140, height: 140)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.7)

                // Status message
                VStack(spacing: OnboardingDesign.Spacing.xs) {
                    Text("Creating your plan")
                        .font(OnboardingDesign.Typography.title2)
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                    Text(messages[currentMessageIndex])
                        .font(OnboardingDesign.Typography.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        .contentTransition(.opacity)
                        .id(currentMessageIndex)
                }
                .opacity(appeared ? 1 : 0)
            }

            Spacer()

            // Processing dots
            HStack(spacing: OnboardingDesign.Spacing.xs) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(OnboardingDesign.Colors.accent.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentMessageIndex % 3 == i ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                            value: currentMessageIndex
                        )
                }
            }
            .padding(.bottom, OnboardingDesign.Spacing.xxxl)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy) {
                appeared = true
            }
            startAnimation()
        }
    }

    private func startAnimation() {
        let totalDuration = 3.0
        let steps = messages.count
        let stepDuration = totalDuration / Double(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.easeInOut(duration: stepDuration)) {
                    progress = Double(i + 1) / Double(steps)
                }
                withAnimation(OnboardingDesign.Animation.standard) {
                    currentMessageIndex = i
                }
            }
        }

        // Auto-advance when done
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.3) {
            onComplete()
        }
    }
}

#Preview {
    CalculatingStepView { }
}
