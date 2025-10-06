import SwiftUI

// MARK: - Interactive Tutorial Card
struct InteractiveTutorialCard: View {
    let step: OnboardingStep
    let onDismiss: () -> Void
    let onInteraction: () -> Void
    
    @State private var cardOffset = CGSize.zero
    @State private var cardRotation: Double = 0
    @State private var isDragging = false
    @State private var hapticTriggered = false
    @State private var showContent = false
    @State private var particlesActive = false
    
    private let haptic = HapticManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Particles in background
                if particlesActive {
                    ParticleEmitter(
                        particleCount: 30,
                        particleLifetime: 2.0,
                        emissionAngle: .degrees(45),
                        colors: [.green.opacity(0.6), .blue.opacity(0.6), .purple.opacity(0.6)]
                    )
                    .allowsHitTesting(false)
                }
                
                // Main card
                GlassmorphismCard(
                    content: cardContent,
                    cornerRadius: 28,
                    glassIntensity: 0.85,
                    borderWidth: 2,
                    shadowRadius: 25,
                    shadowOpacity: 0.2
                )
                .frame(maxWidth: min(geometry.size.width - 40, 380))
                .offset(cardOffset)
                .rotationEffect(.degrees(cardRotation))
                .scaleEffect(isDragging ? 0.98 : 1.0)
                .opacity(showContent ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7),
                    value: isDragging
                )
                .gesture(
                    step.interactionType == .drag ? dragGesture : nil
                )
                .onTapGesture {
                    if step.interactionType == .tap {
                        handleTapInteraction()
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .onAppear {
            appearAnimation()
        }
    }
    
    // MARK: - Card Content
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with icon
            HStack(spacing: 16) {
                Text(step.illustration)
                    .font(.system(size: 56))
                    .foregroundColor(iconColor(for: step.targetElement ?? ""))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if step.interactionType != .automatic {
                        InteractionHint(type: step.interactionType)
                    }
                }
                
                Spacer()
            }
            
            // Description
            Text(step.description)
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.primary.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
            
            // Interactive element based on step type
            interactiveElement()
            
            // Progress indicator
            if let duration = step.duration, duration > 0 && step.interactionType == .automatic {
                AutoProgressBar(duration: duration)
            }
        }
        .padding(28)
    }
    
    // MARK: - Interactive Elements
    @ViewBuilder
    private func interactiveElement() -> some View {
        switch step.targetElement {
        case "budget_creation":
            MockBudgetCreator()
        case "period_picker":
            MockPeriodPicker()
        case "categories":
            MockCategorySelector()
        case "planning":
            MockBudgetPlanner()
        case "transactions":
            MockTransactionEntry()
        case "analytics":
            MockAnalyticsPreview()
        case "completion":
            CompletionCelebration()
        default:
            EmptyView()
        }
    }
    
    // MARK: - Gestures
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                cardOffset = value.translation
                cardRotation = Double(value.translation.width / 20)
                isDragging = true
                
                // Haptic feedback at threshold
                if abs(value.translation.width) > 100 && !hapticTriggered {
                    haptic.impact(.medium)
                    hapticTriggered = true
                }
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    if abs(value.translation.width) > 150 {
                        // Card dismissed
                        cardOffset = CGSize(
                            width: value.translation.width > 0 ? 500 : -500,
                            height: 0
                        )
                        haptic.notification(.success)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                            onInteraction()
                        }
                    } else {
                        // Snap back
                        cardOffset = .zero
                        cardRotation = 0
                    }
                }
                isDragging = false
                hapticTriggered = false
            }
    }
    
    // MARK: - Interactions
    private func handleTapInteraction() {
        haptic.impact(.light)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            particlesActive = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onInteraction()
        }
    }
    
    // MARK: - Animations
    private func appearAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            showContent = true
        }
        
        if step.targetElement == "budget_header" {
            particlesActive = true
        }
    }
    
    // MARK: - Helpers
    private func iconColor(for elementId: String) -> Color {
        switch elementId {
        case "welcome": return .blue
        case "budget_creation": return .green
        case "period_picker": return .orange
        case "categories": return .purple
        case "planning": return .pink
        case "transactions": return .cyan
        case "analytics": return .indigo
        case "completion": return .green
        default: return .blue
        }
    }
}

// MARK: - Interaction Hint
struct InteractionHint: View {
    let type: OnboardingStep.InteractionType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var icon: String {
        switch type {
        case .tap: return "hand.tap.fill"
        case .swipe: return "hand.draw.fill"
        case .drag: return "arrow.left.and.right"
        case .interactive: return "hand.raised.fill"
        default: return "sparkles"
        }
    }
    
    private var text: String {
        switch type {
        case .tap: return "Tap to continue"
        case .swipe: return "Swipe to dismiss"
        case .drag: return "Drag to explore"
        case .interactive: return "Interact to proceed"
        default: return ""
        }
    }
}

// MARK: - Auto Progress Bar
struct AutoProgressBar: View {
    let duration: TimeInterval
    @State private var progress: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Auto-advancing...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(duration - (progress * duration)))s")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.blue)
            }
            
            FloatingProgressBar(progress: progress, totalSteps: 8, currentStep: 1)
        }
        .onAppear {
            withAnimation(.linear(duration: duration)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Mock Interactive Components
struct MockBudgetCreator: View {
    @State private var budgetName = ""
    @State private var selectedCurrency = "USD"
    @State private var selectedIcon = "dollarsign.circle.fill"
    
    let currencies = ["USD", "EUR", "GBP", "JPY"]
    let icons = ["dollarsign.circle.fill", "creditcard.fill", "banknote.fill", "chart.pie.fill"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Name input
            TextField("Budget Name", text: $budgetName)
                .textFieldStyle(.roundedBorder)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 1.5)) {
                            budgetName = "Personal Budget"
                        }
                    }
                }
            
            // Currency selector
            HStack(spacing: 8) {
                ForEach(currencies, id: \.self) { currency in
                    CurrencyChip(
                        currency: currency,
                        isSelected: selectedCurrency == currency,
                        action: { selectedCurrency = currency }
                    )
                }
            }
            
            // Icon selector
            HStack(spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    IconChip(
                        systemName: icon,
                        isSelected: selectedIcon == icon,
                        action: { selectedIcon = icon }
                    )
                }
            }
        }
    }
}

struct CurrencyChip: View {
    let currency: String
    let isSelected: Bool
    let action: () -> Void
    private let hapticManager = HapticManager()

    var body: some View {
        Button(action: {
            hapticManager.selection()
            action()
        }) {
            Text(currency)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct IconChip: View {
    let systemName: String
    let isSelected: Bool
    let action: () -> Void
    private let hapticManager = HapticManager()

    var body: some View {
        Button(action: {
            hapticManager.selection()
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color.green : Color.gray.opacity(0.2))
                )
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct MockPeriodPicker: View {
    @State private var selectedPeriod = "Monthly"
    let periods = ["Monthly", "Quarterly", "Yearly"]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(periods, id: \.self) { period in
                PeriodOption(
                    period: period,
                    isSelected: selectedPeriod == period,
                    action: { selectedPeriod = period }
                )
            }
        }
    }
}

struct PeriodOption: View {
    let period: String
    let isSelected: Bool
    let action: () -> Void
    private let hapticManager = HapticManager()

    var body: some View {
        Button(action: {
            hapticManager.selection()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(period)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.orange : Color.gray.opacity(0.2))
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var icon: String {
        switch period {
        case "Monthly": return "calendar"
        case "Quarterly": return "calendar.badge.plus"
        case "Yearly": return "calendar.circle"
        default: return "calendar"
        }
    }
}

struct MockCategorySelector: View {
    @State private var categories: [String] = ["Food", "Transport", "Entertainment"]
    @State private var draggedCategory: String?
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(categories, id: \.self) { category in
                CategoryRow(category: category)
                    .onDrag {
                        self.draggedCategory = category
                        return NSItemProvider(object: category as NSString)
                    }
            }
        }
    }
}

struct CategoryRow: View {
    let category: String
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: icon(for: category))
                .font(.system(size: 16))
                .foregroundColor(.blue)
            
            Text(category)
                .font(.system(size: 15, weight: .medium))
            
            Spacer()
            
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(isHovered ? 0.5 : 0), lineWidth: 2)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
    
    private func icon(for category: String) -> String {
        switch category {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Entertainment": return "tv.fill"
        default: return "square.grid.2x2"
        }
    }
}

struct MockBudgetPlanner: View {
    @State private var amount: Double = 500
    private let hapticManager = HapticManager()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Monthly Budget")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text("$\(Int(amount))")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }

            Slider(value: $amount, in: 0...2000, step: 100)
                .accentColor(.green)
                .onTapGesture {
                    hapticManager.sliderChange()
                }

            // Mini pie chart
            MiniPieChart(value: amount / 2000)
        }
    }
}

struct MiniPieChart: View {
    let value: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
            
            Text("\(Int(value * 100))%")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
        }
        .frame(width: 60, height: 60)
    }
}

struct MockTransactionEntry: View {
    @State private var amount = ""
    @State private var showCamera = false
    private let hapticManager = HapticManager()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)

                TextField("Enter amount", text: $amount)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
            }

            Button(action: {
                hapticManager.buttonTap()
                showCamera.toggle()
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Scan Receipt")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            .scaleEffect(showCamera ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showCamera)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    amount = "45.99"
                }
            }
        }
    }
}

struct MockAnalyticsPreview: View {
    @State private var chartValues: [Double] = []
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                VStack {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: chartValues.indices.contains(index) ? CGFloat(chartValues[index]) : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index) * 0.1),
                            value: chartValues
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: 60)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                chartValues = [20, 35, 50, 30, 45, 25, 40]
            }
        }
    }
}

struct CompletionCelebration: View {
    @State private var showConfetti = false
    @State private var checkmarkScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView()
            }
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(checkmarkScale)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.5),
                        value: checkmarkScale
                    )
                
                Text("You're all set!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }
        }
        .onAppear {
            checkmarkScale = 1.2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkmarkScale = 1.0
                showConfetti = true
            }
        }
    }
}