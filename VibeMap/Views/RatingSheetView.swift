import SwiftUI

struct RatingSheetView: View {
    @ObservedObject var viewModel: VibeMapViewModel
    @Environment(\.dismiss) private var dismiss

    let draft: RatingDraft

    @State private var selectedTags: [VibeTag] = []
    @State private var revealedSubmission: RatingSubmission?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ratingForm
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                RatingSheetBackground(place: displayedPlace)
            }
            .presentationDetents([.height(presentationHeight)])
            .presentationBackground(VibeDesign.sheetBackground)
            .onAppear {
                prefillExistingRatingIfNeeded()
            }
    }

    private var ratingForm: some View {
        VStack(alignment: .leading, spacing: 6) {
            sheetGrip
            ratingToolbar
            ratingControls
        }
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var sheetGrip: some View {
        Capsule()
            .fill(Color.black.opacity(0.18))
            .frame(width: 42, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
    }

    private var ratingToolbar: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top, spacing: 12) {
                header
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 7) {
                    Button {
                        viewModel.closeRatingFlow()
                        dismiss()
                    } label: {
                        Text(revealedSubmission == nil ? "Cancel" : "Done")
                    }
                    .font(.headline)
                    .fixedSize()
                    .foregroundStyle(VibeDesign.primary)
                    .padding(.top, 3)

                    if displayedPlace.hasRatings && revealedSubmission == nil {
                        CommunityPulseView(
                            place: displayedPlace,
                            maxItems: 2,
                            layout: .vertical,
                            showsCount: true,
                            compact: true
                        )
                        .frame(maxWidth: 150, alignment: .trailing)
                    }

                    if revealedSubmission == nil {
                        SharePlaceButton(
                            place: displayedPlace,
                            title: "Share",
                            isCompact: true
                        )
                    }
                }
                .layoutPriority(1)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 4)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(displayedPlace.name)
                .font(.system(size: 23, weight: .black, design: .default))
                .foregroundStyle(VibeDesign.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(2)

            if !displayedPlace.locationLine.isEmpty {
                AddressDirectionsLink(place: displayedPlace)
            }

            if let category = displayedPlace.displayCategory {
                VenueCategoryLabel(category: category)
                    .padding(.top, 2)
            }
        }
    }

    private var ratingControls: some View {
        VStack(alignment: .leading, spacing: 9) {
            if let revealedSubmission {
                PostSubmissionRevealView(submission: revealedSubmission, initialPlace: draft.place)
            } else {
                preSubmissionDiscovery

                vibeGrid

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                submitSection
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 2)
    }

    private var displayedPlace: VibePlace {
        revealedSubmission?.place ?? viewModel.ratingDraft?.place ?? draft.place
    }

    private var presentationHeight: CGFloat {
        guard let revealedSubmission else {
            return displayedPlace.name.count > 20 ? 556 : 540
        }

        let selectedRows = max(1, revealedSubmission.rating.selectedVibeTags.count)
        let communityRows = isFirstVibe(revealedSubmission)
            ? 1
            : max(1, min(3, revealedSubmission.place.stats?.visibleTopVibes.count ?? 0))
        let comparisonRows = max(selectedRows, communityRows)
        let titleExtra: CGFloat = displayedPlace.name.count > 24 ? 22 : 0

        return min(520, max(380, 315 + CGFloat(comparisonRows) * 48 + titleExtra))
    }

    private func isFirstVibe(_ submission: RatingSubmission) -> Bool {
        submission.discovery?.wasFirstVibe == true || (draft.place.vibeCount == 0 && submission.place.vibeCount == 1)
    }

    @ViewBuilder
    private var preSubmissionDiscovery: some View {
        if !displayedPlace.hasRatings {
            HStack(spacing: 8) {
                DiscoverySignalPill(signal: .firstToVibe, compact: true)

                Spacer(minLength: 0)
            }
        } else if let signal = displayedPlace.primaryDiscoverySignal, signal != .needsMoreVibes {
            HStack {
                DiscoverySignalPill(signal: signal, compact: true)

                Spacer(minLength: 0)
            }
        }
    }

    private var vibeGrid: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Pick one to three vibes")
                .font(.headline.weight(.black))

            VStack(alignment: .leading, spacing: 6) {
                VibeGridChoiceGroup(
                    group: .loveIt,
                    tags: tags(in: .loveIt),
                    selectedTags: selectedTags,
                    onToggle: toggle
                )

                VibeGridChoiceGroup(
                    group: .its,
                    tags: tags(in: .its),
                    selectedTags: selectedTags,
                    onToggle: toggle
                )

                VibeGridChoiceGroup(
                    group: .skipIt,
                    tags: tags(in: .skipIt),
                    selectedTags: selectedTags,
                    onToggle: toggle
                )
            }
        }
    }

    private var orderedVibes: [VibeTag] {
        VibeTag.bestToWorst(viewModel.allowedVibes)
    }

    private func tags(in group: VibeGuidanceGroup) -> [VibeTag] {
        orderedVibes.filter { $0.guidanceGroup == group }
    }

    private var submitSection: some View {
        VStack(spacing: 2) {
            submitButton

            Text("Select one to three vibes.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(VibeDesign.secondaryText)
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 0)
    }

    private var submitButton: some View {
        Button {
            Task {
                await submit()
            }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                }
                Text(submitTitle)
            }
            .font(.headline.weight(.black))
            .foregroundStyle(selectedTags.isEmpty ? VibeDesign.secondaryText : Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(submitButtonBackground, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(selectedTags.isEmpty ? VibeDesign.hairline : Color.white.opacity(0.16), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .contentShape(Capsule())
        .shadow(color: selectedTags.isEmpty ? .black.opacity(0.04) : VibeDesign.pressedShadow, radius: 12, y: 5)
        .disabled(isSubmitting || selectedTags.isEmpty)
    }

    private var submitButtonBackground: Color {
        selectedTags.isEmpty ? VibeDesign.controlBackground.opacity(0.86) : VibeDesign.primary
    }

    private var submitTitle: String {
        if isSubmitting {
            return "Submitting"
        }

        if isEditingExistingRating {
            return "Update vibes"
        }

        return "Submit vibes"
    }

    private var isEditingExistingRating: Bool {
        displayedPlace.myRating != nil && revealedSubmission == nil
    }

    private func toggle(_ tag: VibeTag) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
            return
        }

        if selectedTags.count == 3 {
            selectedTags.removeFirst()
        }
        selectedTags.append(tag)
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil

        do {
            let submission = try await viewModel.submitRating(vibeTags: selectedTags)
            selectedTags = submission.rating.selectedVibeTags
            revealedSubmission = submission
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    private func prefillExistingRatingIfNeeded() {
        guard selectedTags.isEmpty,
              let myRating = displayedPlace.myRating else {
            return
        }

        selectedTags = myRating.selectedVibeTags
    }
}

private struct RatingSheetBackground: View {
    let place: VibePlace

    var body: some View {
        ZStack {
            VibeDesign.sheetBackground.opacity(0.90)

            if let vibe = place.stats?.visibleTopVibes.first?.vibeTag {
                LinearGradient(
                    colors: [
                        vibe.visualStyle.color.opacity(0.05),
                        Color.clear,
                        VibeDesign.sheetBackground.opacity(0.20)
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            }
        }
        .ignoresSafeArea()
    }
}

private struct PostSubmissionRevealView: View {
    let submission: RatingSubmission
    let initialPlace: VibePlace

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(agreementMessage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(VibeDesign.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(VibeDesign.selectedFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(VibeDesign.primary.opacity(0.16), lineWidth: 1)
                }

            HStack(alignment: .top, spacing: 10) {
                VibeComparisonColumn(
                    title: "You picked",
                    tags: submission.rating.selectedVibeTags
                )

                CommunityComparisonColumn(
                    title: wasFirstToVibe ? "Everyone else" : "Community",
                    breakdowns: wasFirstToVibe ? [] : Array(submission.place.stats?.visibleTopVibes.prefix(3) ?? [])
                )
            }

            SharePlaceButton(
                place: submission.place,
                selectedTags: submission.rating.selectedVibeTags,
                title: "Share this vibe",
                isProminent: true
            )
        }
    }

    private var agreementMessage: String {
        if wasFirstToVibe {
            return "First vibe logged"
        }

        let userTags = Set(submission.rating.selectedVibeTags)
        let communityTags = Set(submission.place.stats?.visibleTopVibes.prefix(3).map(\.vibeTag) ?? [])

        if !userTags.isDisjoint(with: communityTags) {
            return "You and the internet mostly agree"
        }

        return "You went against the crowd"
    }

    private var wasFirstToVibe: Bool {
        submission.discovery?.wasFirstVibe == true || (initialPlace.vibeCount == 0 && submission.place.vibeCount == 1)
    }
}

private struct VibeComparisonColumn: View {
    let title: String
    let tags: [VibeTag]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(VibeDesign.secondaryText)

            VStack(spacing: 7) {
                ForEach(tags) { tag in
                    ComparisonVibeRow(tag: tag)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct CommunityComparisonColumn: View {
    let title: String
    let breakdowns: [VibeBreakdown]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(VibeDesign.secondaryText)

            if breakdowns.isEmpty {
                Text("No one else yet")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(VibeDesign.primaryText)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                    .padding(.horizontal, 10)
                    .background(VibeDesign.controlBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(VibeDesign.hairline, lineWidth: 1)
                    }
            } else {
                VStack(spacing: 7) {
                    ForEach(breakdowns) { breakdown in
                        ComparisonVibeRow(tag: breakdown.vibeTag, trailingText: "\(breakdown.percentage)%")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct ComparisonVibeRow: View {
    let tag: VibeTag
    var trailingText: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: tag.visualStyle.symbolName)
                .font(.caption.weight(.black))
                .foregroundStyle(tag.visualStyle.color)
                .frame(width: 16)

            Text(tag.rawValue)
                .font(.subheadline.weight(.black))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let trailingText {
                Text(trailingText)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(tag.visualStyle.color)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .padding(.horizontal, 10)
        .background(VibeDesign.controlBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(VibeDesign.hairline, lineWidth: 1)
        }
    }
}

private struct VibeChoiceButtonLabel: View {
    let tag: VibeTag
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconFill)
                    .frame(width: 25, height: 25)

                Image(systemName: tag.visualStyle.symbolName)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(isSelected ? Color.white : tag.visualStyle.color)
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(width: 29, alignment: .center)

            Text(tag.rawValue)
                .font(.system(size: 12.8, weight: .black))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(tag.visualStyle.color)
            }
        }
        .foregroundStyle(VibeDesign.primaryText)
        .frame(maxWidth: .infinity, minHeight: 43, alignment: .leading)
        .padding(.horizontal, 9)
        .background(buttonBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isSelected ? tag.visualStyle.color.opacity(0.70) : VibeDesign.hairline, lineWidth: isSelected ? 2 : 1)
        }
        .shadow(color: isSelected ? tag.visualStyle.color.opacity(0.16) : .black.opacity(0.045), radius: isSelected ? 10 : 7, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var buttonBackground: Color {
        isSelected ? tag.visualStyle.color.opacity(0.12) : VibeDesign.controlBackground
    }

    private var iconFill: Color {
        isSelected ? tag.visualStyle.color.opacity(0.92) : tag.visualStyle.color.opacity(0.14)
    }
}

private struct VibeGridChoiceGroup: View {
    let group: VibeGuidanceGroup
    let tags: [VibeTag]
    let selectedTags: [VibeTag]
    let onToggle: (VibeTag) -> Void

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(tags) { tag in
                    Button {
                        onToggle(tag)
                    } label: {
                        VibeChoiceButtonLabel(tag: tag, isSelected: selectedTags.contains(tag))
                    }
                    .buttonStyle(VibeChoiceButtonStyle())
                    .accessibilityAddTraits(selectedTags.contains(tag) ? .isSelected : [])
                }
            }
        }
    }
}

private struct VibeChoiceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
