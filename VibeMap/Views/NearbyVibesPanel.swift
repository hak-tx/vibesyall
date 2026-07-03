import SwiftUI
import UIKit

struct NearbyVibesPanel: View {
    @ObservedObject var viewModel: VibeMapViewModel
    @Binding var isMinimized: Bool
    @State private var visiblePlaceLimit = 10

    private static let initialExpandedPlaceLimit = 10
    private static let placePageSize = 10
    private static let maximumExpandedPlaceLimit = 60

    var body: some View {
        BottomPanel(onSwipeDown: minimizeIfNeeded) {
            if isMinimized {
                minimizedContent
            } else {
                expandedContent
            }
        }
        .onChange(of: visibleListSignature) { _ in
            visiblePlaceLimit = Self.initialExpandedPlaceLimit
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
                    Text("What's Nearby")
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
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Text("What's Nearby")
                    .font(.title2.weight(.black))
                    .frame(maxWidth: .infinity)

                HStack {
                    if viewModel.isLoadingNearby {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer()

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
                    .accessibilityLabel("Minimize discovery")
                }
            }

            content
        }
    }

    private func minimizeIfNeeded() {
        guard !isMinimized else { return }

        withAnimation(.easeInOut(duration: 0.18)) {
            isMinimized = true
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
            Text("\(viewModel.visibleNearbyPlaceCount) places in this area. Zoom in or tap a cluster to see the list.")
                .font(.subheadline)
                .foregroundStyle(VibeDesign.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
        } else {
            ZStack(alignment: .bottomTrailing) {
                ScrollView(.vertical, showsIndicators: hasScrollableNearbyContent) {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if !opinionPlaces.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(opinionPlaces) { place in
                                    placeButton(for: place, isDiscoveryRow: true)
                                }
                            }
                        }

                        if !nearbyPlaces.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(opinionPlaces.isEmpty ? "Nearby vibes" : "More nearby")
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(VibeDesign.primaryText)

                                ForEach(nearbyPlaces) { place in
                                    placeButton(for: place, isDiscoveryRow: false)
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

                if hasScrollableNearbyContent {
                    scrollCue
                }
            }
            .frame(height: listHeight)
        }
    }

    private func errorView(_ nearbyError: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Could not load nearby vibes.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VibeDesign.primaryText)
            Text(nearbyError)
                .font(.footnote)
                .foregroundStyle(VibeDesign.secondaryText)
                .lineLimit(2)
            Button("Try again") {
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

    private var opinionPlaces: [VibePlace] {
        Array(
            viewModel.visibleNearbyPlaces
                .filter(\.needsOpinion)
                .sorted(by: discoverySort)
                .prefix(min(3, visiblePlaceLimit))
        )
    }

    private var nearbyPlaces: [VibePlace] {
        let opinionIDs = Set(opinionPlaces.map(\.id))
        let remainingLimit = max(visiblePlaceLimit - opinionPlaces.count, 0)
        return Array(
            viewModel.visibleNearbyPlaces
                .filter { !opinionIDs.contains($0.id) }
                .prefix(remainingLimit)
        )
    }

    private func discoverySort(_ lhs: VibePlace, _ rhs: VibePlace) -> Bool {
        let lhsRank = discoveryRank(lhs)
        let rhsRank = discoveryRank(rhs)
        if lhsRank == rhsRank {
            return (lhs.distanceMeters ?? .greatestFiniteMagnitude) < (rhs.distanceMeters ?? .greatestFiniteMagnitude)
        }
        return lhsRank < rhsRank
    }

    private func discoveryRank(_ place: VibePlace) -> Int {
        if place.vibeCount == 0 { return 0 }
        if place.needsMoreVibes { return 1 }
        if place.isHotTake { return 2 }
        return 3
    }

    private var listHeight: CGFloat {
        min(listContentHeight, maxExpandedListHeight)
    }

    private var listContentHeight: CGFloat {
        guard displayedPlaceCount > 0 else { return 0 }

        let sectionCount = nearbyPlaces.isEmpty || opinionPlaces.isEmpty ? 1 : 2
        let rowHeight: CGFloat = 96
        let showMoreHeight: CGFloat = canShowMorePlaces ? 46 : 0
        return CGFloat(displayedPlaceCount) * rowHeight
            + CGFloat(max(displayedPlaceCount - 1, 0)) * 8
            + CGFloat(sectionCount) * 28
            + showMoreHeight
    }

    private var displayedPlaceCount: Int {
        opinionPlaces.count + nearbyPlaces.count
    }

    private var hasScrollableNearbyContent: Bool {
        totalListablePlaceCount > displayedPlaceCount || (displayedPlaceCount > 3 && listContentHeight > listHeight + 1)
    }

    private var totalListablePlaceCount: Int {
        viewModel.visibleNearbyPlaces.count
    }

    private var remainingListablePlaceCount: Int {
        max(totalListablePlaceCount - displayedPlaceCount, 0)
    }

    private var canShowMorePlaces: Bool {
        remainingListablePlaceCount > 0 && visiblePlaceLimit < Self.maximumExpandedPlaceLimit
    }

    private var visibleListSignature: String {
        viewModel.visibleNearbyPlaces.map(\.id).joined(separator: "|")
    }

    private var showMoreButton: some View {
        Button {
            visiblePlaceLimit = min(
                visiblePlaceLimit + Self.placePageSize,
                min(Self.maximumExpandedPlaceLimit, totalListablePlaceCount)
            )
        } label: {
            HStack(spacing: 8) {
                Text("Show \(min(Self.placePageSize, remainingListablePlaceCount)) more")
                Image(systemName: "chevron.down")
            }
            .font(.caption.weight(.black))
            .foregroundStyle(VibeDesign.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(VibeDesign.controlBackground, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(VibeDesign.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show more nearby places")
    }

    private var scrollCue: some View {
        HStack(spacing: 4) {
            Text("More")
            Image(systemName: "chevron.down")
        }
        .font(.caption2.weight(.black))
        .foregroundStyle(VibeDesign.primary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(VibeDesign.sheetBackground.opacity(0.94), in: Capsule())
        .overlay {
            Capsule()
                .stroke(VibeDesign.hairline, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
        .padding(.trailing, 8)
        .padding(.bottom, 6)
        .allowsHitTesting(false)
    }

    private var maxExpandedListHeight: CGFloat {
        let targetPanelHeight = UIScreen.main.bounds.height * 0.40
        let nonListHeight: CGFloat = 92
        return max(160, targetPanelHeight - nonListHeight)
    }

    private var minimizedSubtitle: String {
        let count = viewModel.visibleNearbyPlaceCount
        return "\(count) nearby place\(count == 1 ? "" : "s")"
    }

    private var emptyText: String {
        if viewModel.hasActiveVibeFilters {
            return "No \(viewModel.selectedVibeFilterSummary) vibes nearby yet."
        }
        return "No vibes nearby yet."
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

                HStack(spacing: 7) {
                    Label(picksText, systemImage: "person.2.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VibeDesign.primary)
                        .lineLimit(1)

                    if !place.locationLine.isEmpty {
                        Text(place.locationLine)
                            .font(.caption)
                            .foregroundStyle(VibeDesign.secondaryText)
                            .lineLimit(1)
                    }
                }

                rowSummary
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Label("Vibe", systemImage: "sparkles")
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

    private var picksText: String {
        "\(place.vibeCount)"
    }

    @ViewBuilder
    private var rowSummary: some View {
        if place.hasRatings {
            CommunityPulseView(place: place, maxItems: 2, layout: .horizontal, showsCount: false, compact: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let signal = place.primaryDiscoverySignal {
            DiscoverySignalPill(signal: signal, compact: true)
        }
    }
}
