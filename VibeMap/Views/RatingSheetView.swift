import SwiftUI

private struct RatingSheetContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct RatingSheetView: View {
    @ObservedObject var viewModel: VibeMapViewModel
    @Environment(\.dismiss) private var dismiss

    let draft: RatingDraft

    @State private var selectedTags: [VibeTag] = []
    @State private var revealedSubmission: RatingSubmission?
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var configuredDraftID: RatingDraft.ID?
    @State private var measuredFormHeight: CGFloat = 0
    @State private var showsAllTopVibes = false
    @State private var showsDeleteConfirmation = false

    var body: some View {
        ratingForm
            .id(draft.id)
            .fixedSize(horizontal: false, vertical: true)
            .background {
                GeometryReader { contentGeometry in
                    Color.clear
                        .preference(
                            key: RatingSheetContentHeightKey.self,
                            value: contentGeometry.size.height
                        )
                }
            }
        .background {
            RatingSheetBackground(place: displayedPlace)
        }
            .presentationDetents([.height(presentationHeight)])
            .presentationBackground(VibeDesign.ratingSheetSurface)
            .onAppear {
                configureForCurrentDraftIfNeeded()
            }
            .onChange(of: draft.id) { _, _ in
                configureForCurrentDraftIfNeeded(force: true)
            }
            .onPreferenceChange(RatingSheetContentHeightKey.self) { height in
                let roundedHeight = ceil(height)
                guard roundedHeight > 0,
                      abs(roundedHeight - measuredFormHeight) > 1 else {
                    return
                }

                measuredFormHeight = roundedHeight
            }
            .alert(L10n.string("Delete your vibes?"), isPresented: $showsDeleteConfirmation) {
                Button(L10n.string("Cancel"), role: .cancel) {}
                Button(L10n.string("Delete"), role: .destructive) {
                    Task {
                        await deleteRating()
                    }
                }
            } message: {
                Text(L10n.string("This removes your vibe submission from this place."))
            }
            .alert(
                L10n.string("Couldn't save changes"),
                isPresented: operationErrorIsPresented
            ) {
                Button(L10n.string("OK"), role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? L10n.string("Please try again."))
            }
    }

    private var ratingForm: some View {
        VStack(alignment: .leading, spacing: 4) {
            sheetHeader
            ratingToolbar
            ratingControls
        }
    }

    private var sheetHeader: some View {
        ZStack {
            Capsule()
                .fill(Color.black.opacity(0.18))
                .frame(width: 42, height: 5)

            HStack {
                Spacer(minLength: 0)
                compactDoneButton
            }
        }
        .frame(height: 36)
        .padding(.horizontal, 18)
    }

    private var compactDoneButton: some View {
        Button {
            if revealedSubmission != nil {
                closeSheet()
            } else if isDeleteAction {
                showsDeleteConfirmation = true
            } else {
                Task {
                    await saveAndReveal()
                }
            }
        } label: {
            HStack(spacing: 5) {
                if isSubmitting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }

                Text(L10n.string("Done"))
                    .font(.subheadline.weight(.black))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 13)
            .frame(height: 30)
            .background(VibeDesign.primary, in: Capsule())
            .frame(minWidth: 58, minHeight: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .accessibilityHint(L10n.string("Saves your selected vibes and closes this card."))
    }

    private var ratingToolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                header
                    .frame(maxWidth: .infinity, alignment: .leading)

                compactShareCallout
                    .frame(width: 94, alignment: .topTrailing)
                    .layoutPriority(1)
            }

            if revealedSubmission == nil, displayedPlace.hasRatings {
                rankedVibeChips
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(VibeDesign.placeSummaryBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(VibeDesign.brandBlue.opacity(0.72), lineWidth: 1.5)
        }
        .shadow(color: VibeDesign.primary.opacity(0.12), radius: 12, y: 5)
        .padding(.horizontal, 18)
        .padding(.top, revealedSubmission == nil ? 2 : 12)
    }

    private var compactShareCallout: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(L10n.string("SHARE IT."))
                .font(.system(size: 12.5, weight: .black, design: .default))
                .foregroundStyle(VibeDesign.brandBlue)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)

            SharePlaceButton(
                place: displayedPlace,
                selectedTags: selectedTags,
                title: L10n.string("Share"),
                isCompact: true,
                isDense: true,
                showsNudge: false
            )
        }
    }

    private func closeSheet() {
        viewModel.closeRatingFlow()
        dismiss()
    }

    @ViewBuilder
    private var rankedVibeChips: some View {
        if let stats = displayedPlace.stats, stats.ratingCount > 0 {
            VibeSnapshotPanel(
                place: displayedPlace,
                breakdowns: stats.visibleTopVibes,
                showsAll: showsAllTopVibes
            ) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showsAllTopVibes.toggle()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 7) {
                shareStylePlaceBadge

                Text(displayedPlace.name.uppercased())
                    .font(.system(size: placeTitleFontSize, weight: .black, design: .default))
                    .fontWidth(.condensed)
                    .foregroundStyle(VibeDesign.brandBlue)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(2)
            }

            if !displayedPlace.locationLine.isEmpty {
                AddressDirectionsLink(place: displayedPlace, style: .shareCard)
            }

            if let category = displayedPlace.displayCategory {
                VenueCategoryLabel(category: category)
                    .padding(.top, 2)
            }
        }
    }

    private var shareStylePlaceBadge: some View {
        ZStack {
            Circle()
                .fill(VibeDesign.brandBlue)

            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(VibeDesign.brandYellow)
        }
        .frame(width: 31, height: 31)
        .overlay {
            Circle()
                .stroke(Color.white.opacity(0.70), lineWidth: 1)
        }
    }

    private var ratingControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let revealedSubmission {
                PostSubmissionRevealView(submission: revealedSubmission, initialPlace: draft.place)
            } else {
                preSubmissionDiscovery

                vibeGrid
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 2)
    }

    private var displayedPlace: VibePlace {
        revealedSubmission?.place ?? viewModel.ratingDraft?.place ?? draft.place
    }

    private var presentationHeight: CGFloat {
        let fallbackHeight: CGFloat = revealedSubmission == nil ? 620 : 470
        let contentHeight = measuredFormHeight > 0 ? measuredFormHeight : fallbackHeight
        let maximumHeight = max(420, UIScreen.main.bounds.height - activeWindowTopSafeAreaInset - 8)

        return min(
            min(780, maximumHeight),
            max(420, contentHeight + 8)
        )
    }

    private var activeWindowTopSafeAreaInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.top ?? 0
    }

    private var placeTitleFontSize: CGFloat {
        switch displayedPlace.name.count {
        case 0...20:
            return 25
        case 21...30:
            return 22
        case 31...42:
            return 18
        default:
            return 16
        }
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
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.string("Pick one to three vibes"))
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

    private var isEditingExistingRating: Bool {
        displayedPlace.myRating != nil && revealedSubmission == nil
    }

    private var isDeleteAction: Bool {
        isEditingExistingRating && selectedTags.isEmpty
    }

    private var operationErrorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
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

    private func saveAndReveal() async {
        guard !selectedTags.isEmpty else {
            closeSheet()
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let submission = try await viewModel.submitRating(vibeTags: selectedTags)
            withAnimation(.easeInOut(duration: 0.2)) {
                revealedSubmission = submission
            }
            isSubmitting = false
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }

    private func deleteRating() async {
        isSubmitting = true
        errorMessage = nil

        do {
            _ = try await viewModel.deleteRating()
            viewModel.closeRatingFlow()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    private func configureForCurrentDraftIfNeeded(force: Bool = false) {
        guard force || configuredDraftID != draft.id else {
            return
        }

        if configuredDraftID != draft.id {
            measuredFormHeight = 0
        }
        configuredDraftID = draft.id
        selectedTags = []
        revealedSubmission = nil
        isSubmitting = false
        errorMessage = nil
        showsAllTopVibes = false
        showsDeleteConfirmation = false
        prefillExistingRatingIfNeeded()
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
        VibeDesign.ratingSheetSurface
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

            HStack(spacing: 8) {
                VibeSubmissionCountView(place: submission.place, compact: true)

                if let signal = submission.place.primaryDiscoverySignal {
                    DiscoverySignalPill(signal: signal, compact: true)
                }

                Spacer(minLength: 0)
            }

            HStack(alignment: .top, spacing: 10) {
                VibeComparisonColumn(
                    title: L10n.string("You picked"),
                    tags: submission.rating.selectedVibeTags
                )

                CommunityComparisonColumn(
                    title: L10n.string(wasFirstToVibe ? "Everyone else" : "Community"),
                    breakdowns: wasFirstToVibe ? [] : Array(submission.place.stats?.visibleTopVibes.prefix(3) ?? [])
                )
            }

            SharePlaceButton(
                place: submission.place,
                selectedTags: submission.rating.selectedVibeTags,
                title: L10n.string("Share this vibe"),
                isProminent: true
            )
        }
    }

    private var agreementMessage: String {
        if wasFirstToVibe {
            return L10n.string("You helped shape the first read.")
        }

        if submission.place.vibeCount <= 3 {
            return L10n.string("This place is starting to get a vibe.")
        }

        let userTags = Set(submission.rating.selectedVibeTags)
        let communityTags = Set(submission.place.stats?.visibleTopVibes.prefix(3).map(\.vibeTag) ?? [])

        if !userTags.isDisjoint(with: communityTags) {
            return L10n.string("You're with the crowd.")
        }

        return L10n.string("You went against the crowd.")
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
                Text(L10n.string("No one else yet"))
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
            VibeIconImage(tag: tag, size: 12)
                .foregroundStyle(tag.visualStyle.color)
                .frame(width: 16)

            Text(tag.displayName)
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

                VibeIconImage(tag: tag, size: 11)
                    .foregroundStyle(isSelected ? Color.white : tag.visualStyle.color)
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(width: 29, alignment: .center)

            Text(tag.displayName)
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
        .frame(maxWidth: .infinity, minHeight: 39, alignment: .leading)
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
        isSelected ? tag.visualStyle.color.opacity(0.12) : VibeDesign.ratingControlBackground
    }

    private var iconFill: Color {
        isSelected ? tag.visualStyle.color.opacity(0.92) : tag.visualStyle.color.opacity(0.14)
    }
}

private struct VibeSnapshotPanel: View {
    let place: VibePlace
    let breakdowns: [VibeBreakdown]
    let showsAll: Bool
    let onToggleExpanded: () -> Void

    private let collapsedLimit = 2

    private var displayedBreakdowns: [VibeBreakdown] {
        showsAll ? breakdowns : Array(breakdowns.prefix(collapsedLimit))
    }

    private var hasAdditionalBreakdowns: Bool {
        breakdowns.count > collapsedLimit
    }

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: 138, maximum: 220),
                spacing: 6,
                alignment: .top
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(L10n.string("Top vibes here").uppercased())
                    .font(.system(size: 10.5, weight: .black))
                    .foregroundStyle(VibeDesign.brandBlue)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if hasAdditionalBreakdowns {
                    Button(action: onToggleExpanded) {
                        HStack(spacing: 3) {
                            Text(L10n.string(showsAll ? "Less" : "More"))
                            Image(systemName: showsAll ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8, weight: .black))
                        }
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(VibeDesign.brandBlue)
                    }
                    .accessibilityLabel(
                        L10n.string(showsAll ? "Show fewer top vibes" : "Show all top vibes")
                    )
                }

                VibeSubmissionCountView(place: place, compact: true)
            }

            if displayedBreakdowns.count == 1, let breakdown = displayedBreakdowns.first {
                VibeSnapshotCell(breakdown: breakdown)
            } else if showsAll {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 6) {
                        ForEach(displayedBreakdowns) { breakdown in
                            VibeSnapshotCell(breakdown: breakdown)
                                .frame(width: 150)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                    ForEach(displayedBreakdowns) { breakdown in
                        VibeSnapshotCell(breakdown: breakdown)
                    }
                }
            }
        }
        .padding(8)
        .background(
            VibeDesign.brandBlue.opacity(0.055),
            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(VibeDesign.brandBlue.opacity(0.28), lineWidth: 1)
        }
    }
}

private struct VibeSnapshotCell: View {
    let breakdown: VibeBreakdown

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(breakdown.vibeTag.visualStyle.color.opacity(0.14))

                VibeIconImage(tag: breakdown.vibeTag, size: 10)
                    .foregroundStyle(breakdown.vibeTag.visualStyle.color)
            }
            .frame(width: 24, height: 24)

            Text(breakdown.vibeTag.displayName)
                .font(.system(size: 10.5, weight: .black))
                .foregroundStyle(VibeDesign.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(breakdown.percentage)%")
                .font(.system(size: 10.5, weight: .black))
                .foregroundStyle(breakdown.vibeTag.visualStyle.color)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .frame(height: 22)
                .background(Color.white.opacity(0.88), in: Capsule())
        }
        .padding(.horizontal, 7)
        .frame(maxWidth: .infinity, minHeight: 34)
        .background(Color.white.opacity(0.60), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(breakdown.vibeTag.visualStyle.color.opacity(0.20), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.format("%@, %d percent", breakdown.vibeTag.displayName, breakdown.percentage))
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
