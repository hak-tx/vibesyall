import SwiftUI
import UIKit

enum NearbyPlacePagination {
    static func nextLimit(
        currentLimit: Int,
        displayedCount: Int,
        totalCount: Int,
        pageSize: Int,
        maximumLimit: Int
    ) -> Int {
        guard totalCount > displayedCount else {
            return currentLimit
        }

        return min(
            max(currentLimit, displayedCount) + pageSize,
            maximumLimit
        )
    }

    static func appliesInitialSectionCaps(
        isListExpanded: Bool,
        hasRequestedAdditionalPlaces: Bool
    ) -> Bool {
        !isListExpanded && !hasRequestedAdditionalPlaces
    }
}

private struct NearbyDiscoverySection: Identifiable {
    enum Kind: String {
        case trending
        case nearby
        case myVibes
        case earlyReads
    }

    var kind: Kind
    var title: String
    var places: [VibePlace]
    var emphasizesDiscovery: Bool

    var id: Kind { kind }
}

struct NearbyVibesPanel: View {
    @ObservedObject var viewModel: VibeMapViewModel
    @Binding var isMinimized: Bool
    private let availableHeight: CGFloat
    @State private var visiblePlaceLimit = 10
    @State private var isListExpanded = false
    @State private var isShowingMyVibes = false
    @State private var hasRequestedAdditionalPlaces = false

    private static let initialExpandedPlaceLimit = 10
    private static let tallExpandedPlaceLimit = 30
    private static let placePageSize = 10
    private static let maximumExpandedPlaceLimit = 60
    private static let tallPanelTopClearance: CGFloat = 170

    init(
        viewModel: VibeMapViewModel,
        isMinimized: Binding<Bool>,
        availableHeight: CGFloat = UIScreen.main.bounds.height
    ) {
        self.viewModel = viewModel
        self._isMinimized = isMinimized
        self.availableHeight = availableHeight
    }

    var body: some View {
        BottomPanel(onSwipeDown: minimizeIfNeeded, onSwipeUp: expandListIfNeeded) {
            if isMinimized {
                minimizedContent
            } else {
                expandedContent
            }
        }
        .onChange(of: visibleListSignature) { _, _ in
            visiblePlaceLimit = defaultVisiblePlaceLimit
            hasRequestedAdditionalPlaces = false
        }
        .onChange(of: isMinimized) { _, minimized in
            if minimized {
                isListExpanded = false
                visiblePlaceLimit = Self.initialExpandedPlaceLimit
                hasRequestedAdditionalPlaces = false
            }
        }
    }

    private var minimizedContent: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isMinimized = false
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.string("What's Nearby"))
                        .font(.title3.weight(.black))
                        .foregroundStyle(VibeDesign.primaryText)

                    if !minimizedSubtitle.isEmpty {
                        Text(minimizedSubtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(VibeDesign.secondaryText)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.up")
                    .font(.headline.weight(.black))
                    .foregroundStyle(VibeDesign.primary)
                    .frame(width: 36, height: 36)
                    .background(VibeDesign.controlBackground, in: Circle())
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(panelDragGesture)
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            content
        }
    }

    private var header: some View {
        HStack {
            modeToggleButton

            Spacer()

            if viewModel.isLoadingNearby {
                ProgressView()
                    .controlSize(.small)
            }

            Button {
                minimizeIfNeeded()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(VibeDesign.primary)
                    .frame(width: 34, height: 34)
                    .background(VibeDesign.controlBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("Minimize discovery"))
        }
        .overlay {
            Text(headerTitle)
                .font(.title3.weight(.black))
                .foregroundStyle(VibeDesign.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .allowsHitTesting(false)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .simultaneousGesture(panelDragGesture)
    }

    private var modeToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isShowingMyVibes.toggle()
                visiblePlaceLimit = Self.initialExpandedPlaceLimit
                hasRequestedAdditionalPlaces = false
            }
        } label: {
            Text(L10n.string(isShowingMyVibes ? "Nearby" : "My Vibes"))
                .font(.caption.weight(.black))
                .foregroundStyle(isShowingMyVibes ? .white : VibeDesign.primary)
                .lineLimit(1)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(isShowingMyVibes ? VibeDesign.primary : VibeDesign.controlBackground, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(isShowingMyVibes ? Color.clear : VibeDesign.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.string(isShowingMyVibes ? "Show nearby discovery" : "Show my vibes in this area"))
    }

    private var headerTitle: String {
        L10n.string(isShowingMyVibes ? "My Vibes" : "What's Nearby")
    }

    private func minimizeIfNeeded() {
        guard !isMinimized else { return }

        withAnimation(.easeInOut(duration: 0.18)) {
            isListExpanded = false
            isMinimized = true
        }
    }

    private func expandListIfNeeded() {
        guard !isListExpanded || isMinimized else { return }

        withAnimation(.easeInOut(duration: 0.18)) {
            isMinimized = false
            isListExpanded = true
            visiblePlaceLimit = max(visiblePlaceLimit, defaultVisiblePlaceLimit)
        }
    }

    private var panelDragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onEnded(handlePanelDrag)
    }

    private func handlePanelDrag(_ value: DragGesture.Value) {
        guard abs(value.translation.width) < 80 else {
            return
        }

        let actualY = value.translation.height
        let predictedY = value.predictedEndTranslation.height
        let strongestY = abs(predictedY) > abs(actualY) ? predictedY : actualY

        guard abs(strongestY) > 16,
              abs(strongestY) > abs(value.translation.width) else {
            return
        }

        if strongestY > 0 {
            minimizeIfNeeded()
        } else {
            expandListIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let nearbyError = viewModel.nearbyError {
            errorView(nearbyError)
        } else if viewModel.visibleNearbyPlaceCount == 0 && !viewModel.isLoadingNearby {
            Text(emptyText)
                .font(.subheadline)
                .foregroundStyle(VibeDesign.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
        } else if viewModel.isShowingMapCellClusters && viewModel.visibleNearbyPlaces.isEmpty {
            Text(L10n.format("%d places in this area. Zoom in to see the list.", viewModel.visibleNearbyPlaceCount))
                .font(.subheadline)
                .foregroundStyle(VibeDesign.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
        } else if activeDiscoverySections.isEmpty && !viewModel.isLoadingNearby {
            Text(emptyText)
                .font(.subheadline)
                .foregroundStyle(VibeDesign.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
        } else {
            ZStack(alignment: .bottomTrailing) {
                ScrollView(.vertical, showsIndicators: hasScrollableNearbyContent) {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(limitedDiscoverySections) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.title)
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(VibeDesign.primaryText)

                                ForEach(section.places) { place in
                                    placeButton(for: place, isDiscoveryRow: section.emphasizesDiscovery)
                                }
                            }
                        }

                        if canShowMorePlaces {
                            showMoreButton
                        }
                    }
                    .padding(.bottom, hasScrollableNearbyContent ? 18 : 0)
                }
                .scrollIndicators(hasScrollableNearbyContent ? .visible : .hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
            .frame(height: listHeight)
        }
    }

    private func errorView(_ nearbyError: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string("Could not load nearby vibes."))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VibeDesign.primaryText)
            Text(nearbyError)
                .font(.footnote)
                .foregroundStyle(VibeDesign.secondaryText)
                .lineLimit(2)
            Button(L10n.string("Try again")) {
                Task {
                    await viewModel.loadNearby()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func placeButton(for place: VibePlace, isDiscoveryRow: Bool) -> some View {
        Button {
            viewModel.openRating(for: place)
        } label: {
            NearbyPlaceRow(place: place, emphasizesDiscovery: isDiscoveryRow)
        }
        .buttonStyle(.plain)
    }

    private var activeDiscoverySections: [NearbyDiscoverySection] {
        isShowingMyVibes ? myVibeSections : discoverySections
    }

    private var discoverySections: [NearbyDiscoverySection] {
        let places = viewModel.visibleNearbyPlaces
        guard !places.isEmpty else {
            return []
        }

        var usedIDs = Set<String>()
        let earlyReadIDs = Set(places.filter(\.needsMoreVibes).map(\.id))

        func take(_ candidates: [VibePlace]) -> [VibePlace] {
            var selected: [VibePlace] = []

            for place in candidates where !usedIDs.contains(place.id) {
                selected.append(place)
                usedIDs.insert(place.id)
            }

            return selected
        }

        let trending = take(
            places
                .filter { $0.isTrending || ($0.recentVibeCount > 0 && $0.vibeCount >= 8) }
                .sorted(by: trendingSort)
        )

        let nearby = take(
            places
                .filter { !earlyReadIDs.contains($0.id) }
                .sorted(by: nearbySort)
        )

        let earlyReads = take(
            places
                .filter(\.needsMoreVibes)
                .sorted(by: earlyReadSort)
        )

        return [
            NearbyDiscoverySection(
                kind: .trending,
                title: L10n.string("Trending in this area"),
                places: trending,
                emphasizesDiscovery: true
            ),
            NearbyDiscoverySection(
                kind: .nearby,
                title: L10n.string("Nearby"),
                places: nearby.isEmpty ? take(places.sorted(by: nearbySort)) : nearby,
                emphasizesDiscovery: false
            ),
            NearbyDiscoverySection(
                kind: .earlyReads,
                title: L10n.string("Early Reads"),
                places: earlyReads,
                emphasizesDiscovery: true
            )
        ]
        .filter { !$0.places.isEmpty }
    }

    private var myVibeSections: [NearbyDiscoverySection] {
        let myVibes = viewModel.visibleNearbyPlaces
            .filter(isMyVibe)
            .sorted(by: recentlyVibedSort)

        guard !myVibes.isEmpty else {
            return []
        }

        return [
            NearbyDiscoverySection(
                kind: .myVibes,
                title: L10n.string("My Vibes in this area"),
                places: myVibes,
                emphasizesDiscovery: true
            )
        ]
    }

    private var limitedDiscoverySections: [NearbyDiscoverySection] {
        var remaining = visiblePlaceLimit
        return activeDiscoverySections.compactMap { section in
            guard remaining > 0 else {
                return nil
            }

            let sectionLimit = min(remaining, maxInitialRows(for: section.kind))
            let visiblePlaces = Array(section.places.prefix(sectionLimit))
            remaining -= visiblePlaces.count

            guard !visiblePlaces.isEmpty else {
                return nil
            }

            return NearbyDiscoverySection(
                kind: section.kind,
                title: section.title,
                places: visiblePlaces,
                emphasizesDiscovery: section.emphasizesDiscovery
            )
        }
    }

    private func maxInitialRows(for kind: NearbyDiscoverySection.Kind) -> Int {
        guard NearbyPlacePagination.appliesInitialSectionCaps(
            isListExpanded: isListExpanded,
            hasRequestedAdditionalPlaces: hasRequestedAdditionalPlaces
        ),
              visiblePlaceLimit <= Self.initialExpandedPlaceLimit else {
            return Int.max
        }

        switch kind {
        case .trending:
            return 3
        case .nearby:
            return 4
        case .myVibes, .earlyReads:
            return 3
        }
    }

    private func isMyVibe(_ place: VibePlace) -> Bool {
        place.myRating != nil || viewModel.canRevealCommunity(for: place)
    }

    private func trendingSort(_ lhs: VibePlace, _ rhs: VibePlace) -> Bool {
        if lhs.trendingScore != rhs.trendingScore {
            return lhs.trendingScore > rhs.trendingScore
        }

        return nearbySort(lhs, rhs)
    }

    private func nearbySort(_ lhs: VibePlace, _ rhs: VibePlace) -> Bool {
        (lhs.distanceMeters ?? .greatestFiniteMagnitude) < (rhs.distanceMeters ?? .greatestFiniteMagnitude)
    }

    private func recentlyVibedSort(_ lhs: VibePlace, _ rhs: VibePlace) -> Bool {
        if lhs.recentVibeCount != rhs.recentVibeCount {
            return lhs.recentVibeCount > rhs.recentVibeCount
        }

        return nearbySort(lhs, rhs)
    }

    private func earlyReadSort(_ lhs: VibePlace, _ rhs: VibePlace) -> Bool {
        if lhs.vibeCount != rhs.vibeCount {
            return lhs.vibeCount < rhs.vibeCount
        }

        return nearbySort(lhs, rhs)
    }

    private var listHeight: CGFloat {
        min(listContentHeight, maxListHeight)
    }

    private var listContentHeight: CGFloat {
        guard displayedPlaceCount > 0 else { return 0 }

        let sectionCount = limitedDiscoverySections.count
        let rowHeight: CGFloat = 104
        let showMoreHeight: CGFloat = canShowMorePlaces ? 46 : 0
        return CGFloat(displayedPlaceCount) * rowHeight
            + CGFloat(max(displayedPlaceCount - 1, 0)) * 8
            + CGFloat(sectionCount) * 28
            + showMoreHeight
    }

    private var displayedPlaceCount: Int {
        limitedDiscoverySections.reduce(0) { $0 + $1.places.count }
    }

    private var hasScrollableNearbyContent: Bool {
        totalListablePlaceCount > displayedPlaceCount || (displayedPlaceCount > 3 && listContentHeight > listHeight + 1)
    }

    private var totalListablePlaceCount: Int {
        activeDiscoverySections.reduce(0) { $0 + $1.places.count }
    }

    private var remainingListablePlaceCount: Int {
        max(totalListablePlaceCount - displayedPlaceCount, 0)
    }

    private var canShowMorePlaces: Bool {
        remainingListablePlaceCount > 0 && visiblePlaceLimit < Self.maximumExpandedPlaceLimit
    }

    private var visibleListSignature: String {
        activeDiscoverySections
            .flatMap { section in section.places.map { "\(section.kind.rawValue):\($0.id)" } }
            .joined(separator: "|") + "|\(isShowingMyVibes ? "my" : "discovery")"
    }

    private var defaultVisiblePlaceLimit: Int {
        if isListExpanded {
            return min(Self.tallExpandedPlaceLimit, max(totalListablePlaceCount, Self.initialExpandedPlaceLimit))
        }

        return Self.initialExpandedPlaceLimit
    }

    private var showMoreButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                hasRequestedAdditionalPlaces = true
                visiblePlaceLimit = NearbyPlacePagination.nextLimit(
                    currentLimit: visiblePlaceLimit,
                    displayedCount: displayedPlaceCount,
                    totalCount: totalListablePlaceCount,
                    pageSize: Self.placePageSize,
                    maximumLimit: Self.maximumExpandedPlaceLimit
                )
            }
        } label: {
            HStack(spacing: 8) {
                Text(L10n.format("Show %d more", min(Self.placePageSize, remainingListablePlaceCount)))
                Image(systemName: "chevron.down")
            }
            .font(.caption.weight(.black))
            .foregroundStyle(VibeDesign.primary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Capsule())
            .background(VibeDesign.controlBackground, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(VibeDesign.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.string("Show more nearby places"))
    }

    private var maxListHeight: CGFloat {
        let targetPanelHeight = isListExpanded ? tallPanelHeight : standardPanelHeight
        let nonListHeight: CGFloat = 92
        return max(160, targetPanelHeight - nonListHeight)
    }

    private var standardPanelHeight: CGFloat {
        min(max(availableHeight * 0.40, 260), 440)
    }

    private var tallPanelHeight: CGFloat {
        let expandedAvailableHeight = availableHeight - Self.tallPanelTopClearance
        return max(standardPanelHeight, expandedAvailableHeight)
    }

    private var minimizedSubtitle: String {
        let count = viewModel.visibleNearbyPlaceCount
        if isShowingMyVibes {
            return L10n.format("%d vibed in this area", myVibeSections.first?.places.count ?? 0)
        }

        let trendingCount = discoverySections.first { $0.kind == .trending }?.places.count ?? 0
        if trendingCount > 0 {
            return L10n.format("%d trending · %d nearby", trendingCount, count)
        }
        return L10n.count(count, singular: "%d nearby place", plural: "%d nearby places")
    }

    private var emptyText: String {
        if viewModel.hasActiveVibeFilters {
            return L10n.format("No %@ vibes nearby yet.", viewModel.selectedVibeFilterSummary)
        }
        if isShowingMyVibes {
            return L10n.string("No past vibes in this area yet.")
        }
        return L10n.string("No vibes in this area yet.")
    }
}

private struct NearbyPlaceRow: View {
    let place: VibePlace
    let emphasizesDiscovery: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(place.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .fixedSize(horizontal: false, vertical: true)

                metaLine

                rowSummary
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Label(L10n.string("Vibe"), systemImage: "sparkles")
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
                .labelStyle(.titleAndIcon)
                .frame(width: 62, height: 38)
                .background(VibeDesign.primary, in: Capsule())
                .shadow(color: VibeDesign.pressedShadow, radius: 8, y: 3)
        }
        .padding(12)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(rowStroke, lineWidth: 1)
        }
    }

    private var rowBackground: Color {
        emphasizesDiscovery ? VibeDesign.primary.opacity(0.045) : VibeDesign.cardBackground
    }

    private var rowStroke: Color {
        emphasizesDiscovery ? VibeDesign.primary.opacity(0.12) : VibeDesign.hairline
    }

    private var statusSignal: DiscoverySignal? {
        place.primaryDiscoverySignal
    }

    private var metaLine: some View {
        HStack(spacing: 7) {
            if let statusSignal {
                DiscoverySignalPill(signal: statusSignal, compact: true)
                    .fixedSize()
            }

            VibeSubmissionCountView(place: place, compact: true)
                .fixedSize()

            if !place.locationLine.isEmpty {
                Text(place.locationLine)
                    .font(.caption)
                    .foregroundStyle(VibeDesign.secondaryText)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var rowSummary: some View {
        if place.hasRatings {
            CommunityPulseView(place: place, maxItems: 2, layout: .horizontal, showsCount: false, compact: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(L10n.string("No vibes yet"))
                .font(.caption2.weight(.bold))
                .foregroundStyle(VibeDesign.secondaryText)
        }
    }
}
