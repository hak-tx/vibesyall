import CoreImage
import CoreImage.CIFilterBuiltins
import MapKit
import SwiftUI
import UIKit

enum VibeDesign {
    static let primary = Color(red: 0.10, green: 0.16, blue: 0.24)
    static let brandBlue = Color(red: 0.063, green: 0.173, blue: 0.420)
    static let brandYellow = Color(red: 0.875, green: 0.843, blue: 0.443)
    static let primaryText = Color(red: 0.04, green: 0.06, blue: 0.08)
    static let secondaryText = Color(red: 0.43, green: 0.46, blue: 0.50)
    static let linkText = Color(red: 0.25, green: 0.34, blue: 0.43)
    static let sheetBackground = Color(red: 0.98, green: 0.973, blue: 0.957)
    static let ratingSheetSurface = Color(red: 0.945, green: 0.950, blue: 0.940)
    static let ratingControlBackground = Color(red: 0.970, green: 0.972, blue: 0.958)
    static let placeSummaryBackground = Color(red: 0.925, green: 0.932, blue: 0.920)
    static let placeSummaryPanelBackground = Color(red: 0.965, green: 0.955, blue: 0.90)
    static let cardBackground = Color.white.opacity(0.86)
    static let overlayBackground = Color.white.opacity(0.78)
    static let controlBackground = Color.white.opacity(0.68)
    static let selectedFill = Color(red: 0.10, green: 0.16, blue: 0.24).opacity(0.07)
    static let hairline = Color(red: 0.10, green: 0.12, blue: 0.14).opacity(0.10)
    static let softShadow = Color.black.opacity(0.11)
    static let pressedShadow = Color(red: 0.10, green: 0.16, blue: 0.24).opacity(0.20)
}

enum VibeMapDisplayStyle: String, CaseIterable, Identifiable {
    case dark
    case standard
    case satellite

    var id: String {
        rawValue
    }

    var label: String {
        let englishLabel = switch self {
        case .dark:
            "Dark"
        case .standard:
            "Standard"
        case .satellite:
            "Satellite"
        }
        return L10n.string(englishLabel)
    }

    var shortLabel: String {
        let englishLabel = switch self {
        case .dark:
            "Dark"
        case .standard:
            "Map"
        case .satellite:
            "Sat"
        }
        return L10n.string(englishLabel)
    }

    var symbolName: String {
        switch self {
        case .dark:
            "moon.fill"
        case .standard:
            "map.fill"
        case .satellite:
            "globe.americas.fill"
        }
    }

    var style: MapStyle {
        switch self {
        case .dark:
            .standard(elevation: .flat, pointsOfInterest: .all, showsTraffic: false)
        case .standard:
            .standard(elevation: .flat, pointsOfInterest: .all, showsTraffic: false)
        case .satellite:
            .hybrid(elevation: .flat, pointsOfInterest: .all, showsTraffic: false)
        }
    }

    var mapColorScheme: ColorScheme {
        self == .dark ? .dark : .light
    }
}

struct BottomPanel<Content: View>: View {
    private let content: Content
    private let onSwipeDown: (() -> Void)?
    private let onSwipeUp: (() -> Void)?

    init(
        onSwipeDown: (() -> Void)? = nil,
        onSwipeUp: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onSwipeDown = onSwipeDown
        self.onSwipeUp = onSwipeUp
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            grabber

            content
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(VibeDesign.sheetBackground.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        }
        .shadow(color: VibeDesign.softShadow, radius: 18, y: -5)
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }

    private var grabber: some View {
        Color.clear
            .frame(height: 40)
            .overlay {
                Capsule()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: 42, height: 5)
                    .padding(.top, 14)
                    .padding(.bottom, 21)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(panelDragGesture)
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
            onSwipeDown?()
        } else {
            onSwipeUp?()
        }
    }
}

struct VibeSubmissionCountView: View {
    let place: VibePlace
    var compact = false

    var body: some View {
        Label(submissionText, systemImage: "person.2.fill")
            .font(.caption2.weight(.black))
            .foregroundStyle(VibeDesign.secondaryText)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.035), in: Capsule())
            .fixedSize()
    }

    private var submissionText: String {
        guard let ratingCount = place.stats?.ratingCount, ratingCount > 0 else {
            return L10n.string("Be the first")
        }

        let countText = Self.countFormatter.string(from: NSNumber(value: ratingCount)) ?? "\(ratingCount)"
        if compact {
            return L10n.format(ratingCount == 1 ? "%@ vibe" : "%@ vibes", countText)
        }
        return L10n.format(ratingCount == 1 ? "%@ vibe submitted" : "%@ vibes submitted", countText)
    }

    private static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

enum CommunityPulseLayout {
    case horizontal
    case vertical
}

struct CommunityPulseView: View {
    let place: VibePlace
    var maxItems = 2
    var layout: CommunityPulseLayout = .horizontal
    var showsCount = false
    var compact = true

    var body: some View {
        if let stats = place.stats, stats.ratingCount > 0 {
            switch layout {
            case .horizontal:
                horizontalSummary(for: stats)
            case .vertical:
                verticalSummary(for: stats)
            }
        }
    }

    private func horizontalSummary(for stats: PlaceStats) -> some View {
        HStack(spacing: compact ? 8 : 10) {
            if showsCount {
                VibeSubmissionCountView(place: place, compact: compact)
            }

            ForEach(stats.visibleTopVibes.prefix(maxItems)) { breakdown in
                CommunityPulseItem(breakdown: breakdown, compact: compact)
            }
        }
    }

    private func verticalSummary(for stats: PlaceStats) -> some View {
        VStack(alignment: .trailing, spacing: compact ? 4 : 6) {
            if showsCount {
                VibeSubmissionCountView(place: place, compact: compact)
            }

            ForEach(stats.visibleTopVibes.prefix(maxItems)) { breakdown in
                CommunityPulseItem(breakdown: breakdown, compact: compact)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

struct PlaceVibeTotalsCard: View {
    let place: VibePlace
    var maxItems = 2
    @Binding var isExpanded: Bool
    var isAttached = false
    var minimumHeight: CGFloat?

    var body: some View {
        if let stats = place.stats, stats.ratingCount > 0 {
            let visibleVibes = stats.visibleTopVibes
            let displayedVibes = isExpanded ? visibleVibes : Array(visibleVibes.prefix(maxItems))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text(L10n.string("Top vibes here"))
                        .font(.caption2.weight(.black))
                        .textCase(.uppercase)
                        .foregroundStyle(isAttached ? VibeDesign.brandBlue : VibeDesign.brandYellow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 8)

                    vibeCountPill(for: stats.ratingCount)
                }

                ForEach(displayedVibes) { breakdown in
                    PlaceVibeTotalsRow(breakdown: breakdown, isAttached: isAttached)
                }

                if visibleVibes.count > maxItems {
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Label(L10n.string(isExpanded ? "Less" : "More"), systemImage: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(VibeDesign.brandBlue)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.94), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityLabel(L10n.string(isExpanded ? "Show fewer top vibes" : "Show all top vibes"))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(minHeight: minimumHeight, alignment: .top)
            .background {
                cardBackground
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isAttached ? VibeDesign.brandBlue.opacity(0.11) : Color.white.opacity(0.24), lineWidth: 1)
            }
            .shadow(
                color: isAttached ? Color.clear : VibeDesign.brandBlue.opacity(0.22),
                radius: isAttached ? 0 : 8,
                y: isAttached ? 0 : 3
            )
        }
    }

    private func vibeCountPill(for count: Int) -> some View {
        let countText = Self.countFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
        let label = L10n.format(count == 1 ? "%@ vibe" : "%@ vibes", countText)

        return Label(label, systemImage: "person.2.fill")
            .font(.caption2.weight(.black))
            .foregroundStyle(VibeDesign.brandBlue)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.94), in: Capsule())
    }

    @ViewBuilder
    private var cardBackground: some View {
        if isAttached {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(VibeDesign.placeSummaryPanelBackground)
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            VibeDesign.brandBlue,
                            Color(red: 0.04, green: 0.16, blue: 0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

private struct PlaceVibeTotalsRow: View {
    let breakdown: VibeBreakdown
    var isAttached = false

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)

                VibeIconImage(tag: breakdown.vibeTag, size: 10)
                    .foregroundStyle(breakdown.vibeTag.visualStyle.color)
            }
            .frame(width: 24, height: 24)

            Text(breakdown.vibeTag.displayName)
                .font(.caption2.weight(.black))
                .foregroundStyle(isAttached ? VibeDesign.primary : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 6)

            Text("\(breakdown.percentage)%")
                .font(.caption.weight(.black))
                .foregroundStyle(breakdown.vibeTag.visualStyle.color)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.94), in: Capsule())
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isAttached ? VibeDesign.brandBlue.opacity(0.08) : Color.white.opacity(0.13), lineWidth: 1)
        }
    }

    private var rowBackground: Color {
        isAttached ? Color.white.opacity(0.58) : Color.white.opacity(0.13)
    }
}

private struct CommunityPulseItem: View {
    let breakdown: VibeBreakdown
    var compact = true

    var body: some View {
        HStack(spacing: compact ? 4 : 5) {
            VibeIconImage(tag: breakdown.vibeTag, size: compact ? 9 : 10)
                .foregroundStyle(breakdown.vibeTag.visualStyle.color)
                .frame(width: compact ? 12 : 14)

            Text(breakdown.vibeTag.displayName)
                .foregroundStyle(VibeDesign.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("\(breakdown.percentage)%")
                .foregroundStyle(breakdown.vibeTag.visualStyle.color)
                .lineLimit(1)
        }
        .font(compact ? .caption2.weight(.black) : .caption.weight(.black))
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct PlaceMetaActionRow: View {
    let place: VibePlace

    @ViewBuilder
    var body: some View {
        if let category = place.displayCategory {
            HStack(spacing: 10) {
                VenueCategoryLabel(category: category)

                Spacer(minLength: 0)
            }
        }
    }
}

struct VenueCategoryLabel: View {
    let category: String

    var body: some View {
        Label(L10n.category(category), systemImage: symbolName)
            .font(.caption.weight(.bold))
            .foregroundStyle(VibeDesign.secondaryText)
            .lineLimit(1)
            .fixedSize()
    }

    private var symbolName: String {
        Self.symbolName(for: category)
    }

    static func symbolName(for category: String) -> String {
        switch category.lowercased() {
        case "restaurant":
            "fork.knife"
        case "bar", "brewery":
            "wineglass.fill"
        case "park":
            "tree.fill"
        case "music venue", "theater":
            "music.mic"
        case "stadium":
            "sportscourt.fill"
        case "hotel":
            "bed.double.fill"
        case "museum":
            "building.columns.fill"
        case "school":
            "graduationcap.fill"
        case "shop":
            "bag.fill"
        default:
            "tag.fill"
        }
    }
}

struct DiscoverySignalPill: View {
    let signal: DiscoverySignal
    var compact = false

    var body: some View {
        Label(compact ? signal.shortLabel : signal.displayName, systemImage: iconName)
            .font(compact ? .caption2.weight(.black) : .caption.weight(.black))
            .foregroundStyle(VibeDesign.primary)
            .lineLimit(1)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 5 : 7)
            .background(VibeDesign.primary.opacity(0.08), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(VibeDesign.primary.opacity(0.12), lineWidth: 1)
            }
    }

    private var iconName: String {
        switch signal {
        case .firstToVibe:
            "sparkles"
        case .needsMoreVibes:
            "person.2.fill"
        case .hotTake:
            "flame.fill"
        case .hiddenGem:
            "star.fill"
        case .trending:
            "chart.line.uptrend.xyaxis"
        case .localFavorite:
            "heart.fill"
        case .recent:
            "sparkle"
        }
    }
}

struct AddressDirectionsLink: View {
    enum DisplayStyle {
        case standard
        case shareCard
    }

    let place: VibePlace
    var style: DisplayStyle = .standard

    @State private var isChoosingMapApp = false

    var body: some View {
        Button {
            isChoosingMapApp = true
        } label: {
            label
        }
        .buttonStyle(.plain)
        .confirmationDialog(L10n.string("Learn More"), isPresented: $isChoosingMapApp, titleVisibility: .visible) {
            if !place.isGoogleProviderPlace {
                Button(L10n.string("Apple Maps")) {
                    MapPlaceLauncher.openAppleMaps(for: place)
                }
            }

            Button(L10n.string("Google Maps")) {
                MapPlaceLauncher.openGoogleMaps(for: place)
            }

            Button(L10n.string("Cancel"), role: .cancel) {}
        } message: {
            Text(L10n.string("Contact, directions, pictures, etc."))
        }
        .accessibilityLabel(L10n.format("Open %@ in Maps", place.name))
    }

    @ViewBuilder
    private var label: some View {
        switch style {
        case .standard:
            standardLabel
        case .shareCard:
            shareCardLabel
        }
    }

    private var standardLabel: some View {
        HStack(alignment: .top, spacing: 5) {
            Image(systemName: "map")
                .font(.caption.weight(.bold))
                .foregroundStyle(VibeDesign.linkText.opacity(0.82))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 1) {
                if let streetLine = place.addressStreetLine {
                    Text(streetLine)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                if let localityLine = place.addressLocalityLine {
                    Text(localityLine)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                } else if place.addressStreetLine == nil {
                    Text(place.locationLine)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(VibeDesign.linkText)
            .underline(true, color: VibeDesign.linkText.opacity(0.70))
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var shareCardLabel: some View {
        HStack(alignment: .center, spacing: 7) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(VibeDesign.brandBlue)
                .frame(width: 18, height: 18)

            Text(shareCardAddressText)
                .font(.system(size: 16, weight: .black, design: .default))
                .foregroundStyle(VibeDesign.brandBlue)
                .underline(true, color: VibeDesign.brandBlue.opacity(0.72))
                .lineLimit(2)
                .minimumScaleFactor(0.62)
                .multilineTextAlignment(.leading)

            Image(systemName: "arrow.up.right.square.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(VibeDesign.brandBlue)
                .accessibilityHidden(true)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var shareCardAddressText: String {
        if !place.locationLine.isEmpty {
            return place.locationLine
        }

        return [place.addressStreetLine, place.addressLocalityLine]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

@MainActor
private enum MapPlaceLauncher {
    static func openAppleMaps(for place: VibePlace) {
        Task {
            let mapItem = await appleMapItem(for: place)
            mapItem.openInMaps(launchOptions: nil)
        }
    }

    static func openGoogleMaps(for place: VibePlace) {
        guard let webURL = googleWebPlaceURL(for: place) else {
            return
        }

        if let appURL = googleAppPlaceURL(for: place),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }

        UIApplication.shared.open(webURL)
    }

    private static func appleMapItem(for place: VibePlace) async -> MKMapItem {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = place.mapPlaceSearchQuery
        request.region = MKCoordinateRegion(center: place.coordinate, latitudinalMeters: 700, longitudinalMeters: 700)
        request.resultTypes = .pointOfInterest

        if let response = try? await MKLocalSearch(request: request).start(),
           let mapItem = bestMapItem(from: response.mapItems, for: place) {
            return mapItem
        }

        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
        mapItem.name = place.name
        return mapItem
    }

    private static func bestMapItem(from mapItems: [MKMapItem], for place: VibePlace) -> MKMapItem? {
        let origin = CLLocation(latitude: place.latitude, longitude: place.longitude)
        let placeName = normalized(place.name)
        let closeItems = mapItems
            .compactMap { item -> (item: MKMapItem, distance: CLLocationDistance)? in
                guard let location = item.placemark.location else { return nil }
                let distance = location.distance(from: origin)
                guard distance <= 250 else { return nil }
                return (item, distance)
            }
            .sorted { $0.distance < $1.distance }

        return closeItems.first { entry in
            let itemName = normalized(entry.item.name ?? "")
            return !itemName.isEmpty && (itemName.contains(placeName) || placeName.contains(itemName))
        }?.item ?? closeItems.first?.item
    }

    private static func googleAppPlaceURL(for place: VibePlace) -> URL? {
        var components = URLComponents(string: "comgooglemaps://")
        components?.queryItems = [
            URLQueryItem(name: "q", value: place.mapPlaceSearchQuery),
            URLQueryItem(name: "center", value: "\(place.latitude),\(place.longitude)")
        ]
        return components?.url
    }

    private static func googleWebPlaceURL(for place: VibePlace) -> URL? {
        var components = URLComponents(string: "https://www.google.com/maps/search/")
        var queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: place.mapPlaceSearchQuery)
        ]

        if place.isGoogleProviderPlace,
           let providerPlaceId = place.providerPlaceId,
           !providerPlaceId.isEmpty {
            queryItems.append(URLQueryItem(name: "query_place_id", value: providerPlaceId))
        }

        components?.queryItems = queryItems
        return components?.url
    }

    private static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private extension VibePlace {
    var mapPlaceSearchQuery: String {
        [name, locationLine, country]
            .compactMap { value in
                guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return nil
                }
                return value
            }
            .joined(separator: ", ")
    }
}

struct CompactPlaceStatsView: View {
    let place: VibePlace

    var body: some View {
        if let stats = place.stats, stats.ratingCount > 0 {
            VStack(alignment: .leading, spacing: 4) {
                VibeSubmissionCountView(place: place)

                if !stats.visibleTopVibes.isEmpty {
                    CommunityPulseView(place: place, maxItems: 3, layout: .horizontal, showsCount: false, compact: true)
                }
            }
        }
    }
}

struct SharePlaceButton: View {
    let place: VibePlace
    var selectedTags: [VibeTag] = []
    var title = "Share"
    var isProminent = false
    var isCompact = false
    var isDense = false
    var showsNudge = true

    @State private var sharePayload: VibeSharePayload?
    @State private var isRendering = false

    var body: some View {
        HStack(spacing: 6) {
            if showsCompactNudge {
                shareNudgeArrow
            }

            shareButton
        }
        .frame(maxWidth: isProminent ? .infinity : nil, alignment: .trailing)
        .sheet(item: $sharePayload) { payload in
            ShareActivityView(activityItems: payload.activityItems)
        }
        .accessibilityLabel(L10n.format("Share %@", place.name))
    }

    private var shareButton: some View {
        Button {
            Task {
                await prepareSharePayload()
            }
        } label: {
            buttonLabel
                .frame(maxWidth: isProminent ? .infinity : nil)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: isProminent ? .infinity : nil)
        .frame(height: buttonHeight)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            VibeDesign.brandBlue,
                            VibeDesign.primary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: VibeDesign.brandBlue.opacity(isProminent ? 0.26 : 0.34), radius: isProminent ? 12 : 10, y: 4)
        .shadow(color: VibeDesign.brandYellow.opacity(isCompact ? 0.14 : 0.08), radius: isCompact ? 8 : 5)
        .contentShape(Capsule())
        .disabled(isRendering)
    }

    private var shareNudgeArrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 22, weight: .black))
            .foregroundStyle(VibeDesign.brandBlue)
            .shadow(color: VibeDesign.brandBlue.opacity(0.22), radius: 2, y: 1)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    private var buttonLabel: some View {
        HStack(spacing: isDense ? 5 : (isCompact ? 7 : 9)) {
            Image(systemName: isRendering ? "hourglass" : "square.and.arrow.up")
                .font(iconFont)
                .foregroundStyle(VibeDesign.brandYellow)
                .frame(width: isDense ? 15 : (isCompact ? 18 : 22))

            Text(L10n.string(title))
                .font(buttonFont)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var buttonFont: Font {
        if isProminent {
            return .title3.weight(.black)
        }

        if isDense {
            return .caption.weight(.black)
        }

        return isCompact ? .subheadline.weight(.black) : .headline.weight(.black)
    }

    private var iconFont: Font {
        if isProminent {
            return .headline.weight(.black)
        }

        if isDense {
            return .caption.weight(.black)
        }

        return isCompact ? .subheadline.weight(.black) : .headline.weight(.black)
    }

    private var horizontalPadding: CGFloat {
        if isProminent {
            return 18
        }

        if isDense {
            return 12
        }

        return isCompact ? 16 : 18
    }

    private var buttonHeight: CGFloat {
        if isProminent {
            return 52
        }

        if isDense {
            return 32
        }

        return isCompact ? 38 : 46
    }

    private var showsCompactNudge: Bool {
        showsNudge && isCompact && !isProminent && !isRendering
    }

    @MainActor
    private func prepareSharePayload() async {
        isRendering = true
        defer { isRendering = false }

        let tags = effectiveSelectedTags
        let card = VibeShareCardView(place: place, selectedTags: tags)
            .frame(width: 1536, height: 1024)
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 1

        guard let image = renderer.uiImage else {
            return
        }

        sharePayload = VibeSharePayload(
            image: image,
            text: shareText(for: tags)
        )
    }

    private var effectiveSelectedTags: [VibeTag] {
        let normalizedTags = VibeTag.normalizedSelection(selectedTags)
        if !normalizedTags.isEmpty {
            return normalizedTags
        }

        return place.myRating?.selectedVibeTags ?? []
    }

    private func shareText(for _: [VibeTag]) -> String {
        L10n.format("Check the vibes on %@.", place.name)
    }
}

private struct VibeSharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
    let text: String

    var activityItems: [Any] {
        [image, text]
    }
}

private struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct VibeShareCardView: View {
    let place: VibePlace
    let selectedTags: [VibeTag]

    private let cardBackground = Color(red: 0.99, green: 0.965, blue: 0.925)
    private let panelBackground = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.24, blue: 0.55),
            Color(red: 0.04, green: 0.17, blue: 0.39)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            cardBackground

            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.18), radius: 30, y: 18)
                .padding(44)

            HStack(spacing: 38) {
                leftColumn
                    .frame(width: 850, alignment: .leading)

                Rectangle()
                    .fill(VibeDesign.brandBlue.opacity(0.15))
                    .frame(width: 2)
                    .padding(.vertical, 8)

                rightColumn
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 58)
        }
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            vibePanel

            sharePrompt
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 24) {
                SharePlaceBadge()

                VStack(alignment: .leading, spacing: 10) {
                    Text(place.name.uppercased())
                        .font(.system(size: 80, weight: .black))
                        .fontWidth(.condensed)
                        .foregroundStyle(VibeDesign.brandBlue)
                        .lineLimit(2)
                        .minimumScaleFactor(0.50)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(VibeDesign.brandBlue)
                            .frame(width: 36, height: 36)

                        Text(addressText)
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(VibeDesign.brandBlue)
                            .lineLimit(2)
                            .minimumScaleFactor(0.62)
                    }
                }
            }
        }
    }

    private var vibePanel: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                ForEach(Array(vibeRows.enumerated()), id: \.offset) { _, row in
                    ShareCardVibeRow(model: row)
                }
            }

            Spacer(minLength: 12)

            HStack(spacing: 22) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 50, weight: .black))
                    .foregroundStyle(VibeDesign.brandYellow)
                    .frame(width: 82)

                Text(vibeCountHeadline)
                    .font(.system(size: 72, weight: .black))
                    .fontWidth(.condensed)
                    .foregroundStyle(VibeDesign.brandYellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(vibeCountLabel)
                    .font(.system(size: 29, weight: .black))
                    .fontWidth(.condensed)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 0)
            }
            .padding(.top, 22)
            .padding(.horizontal, 18)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: vibePanelHeight, maxHeight: vibePanelHeight, alignment: .top)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private var sharePrompt: some View {
        Text(L10n.string("AGREE OR DISAGREE?"))
            .font(.system(size: 94, weight: .black))
            .fontWidth(.condensed)
            .foregroundStyle(VibeDesign.brandBlue)
            .lineLimit(1)
            .minimumScaleFactor(0.54)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 10)
    }

    private var vibePanelHeight: CGFloat {
        switch vibeRows.count {
        case 0...1:
            return 376
        case 2:
            return 440
        default:
            return 590
        }
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.string("SEE IT.\nVIBE IT.\nSHARE IT."))
                .font(.system(size: 88, weight: .black))
                .fontWidth(.condensed)
                .foregroundStyle(VibeDesign.brandBlue)
                .lineSpacing(10)
                .lineLimit(3)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, maxHeight: 360, alignment: .topLeading)

            Rectangle()
                .fill(VibeDesign.brandYellow)
                .frame(height: 7)
                .padding(.top, 10)
                .padding(.trailing, 14)

            HStack {
                Spacer(minLength: 0)

                ShareCardBrandMark(size: 292)

                Spacer(minLength: 0)
            }
            .padding(.top, 18)

            Spacer(minLength: 8)

            HStack(alignment: .bottom, spacing: 20) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(L10n.string("GET THE APP!"))
                            .font(.system(size: 27, weight: .black))
                            .fontWidth(.condensed)
                            .foregroundStyle(VibeDesign.brandBlue)
                            .lineLimit(1)

                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(VibeDesign.brandBlue)
                            .rotationEffect(.degrees(-5))
                    }

                    ShareAppStoreBadge(width: 246, height: 82)

                    Text(L10n.string("Scan or tap the link to open VIBES Y'ALL."))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(VibeDesign.brandBlue.opacity(0.72))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ShareQRCodeView(url: AppConfig.appStoreURL, size: 182, codeSize: 146)
                    .padding(.bottom, 16)
                    .layoutPriority(1)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private struct ShareCardBrandMark: View {
        let size: CGFloat

        var body: some View {
            Image("BrandLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                        .stroke(Color.white.opacity(0.82), lineWidth: 4)
                }
                .shadow(color: VibeDesign.brandBlue.opacity(0.22), radius: 18, y: 10)
        }
    }

    private struct SharePlaceBadge: View {
        var body: some View {
            ZStack {
                Circle()
                    .fill(VibeDesign.brandBlue)
                    .frame(width: 88, height: 88)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 45, weight: .black))
                    .foregroundStyle(VibeDesign.brandYellow)
            }
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.64), lineWidth: 2)
            }
        }

    }

    private var vibeRows: [ShareCardVibeRowModel] {
        let tags = rankedShareTags(VibeTag.normalizedSelection(selectedTags))
        if !tags.isEmpty {
            return tags.prefix(3).map {
                ShareCardVibeRowModel(tag: $0, title: $0.displayName, percentageText: selectedPercentageText(for: $0))
            }
        }

        if let stats = place.stats, stats.ratingCount > 0 {
            return stats.visibleTopVibes.prefix(3).map {
                ShareCardVibeRowModel(tag: $0.vibeTag, title: $0.vibeTag.displayName, percentageText: "\($0.percentage)%")
            }
        }

        return [
            ShareCardVibeRowModel(tag: .iconic, title: L10n.string("Be first"), percentageText: L10n.string("VIBE IT"))
        ]
    }

    private func rankedShareTags(_ tags: [VibeTag]) -> [VibeTag] {
        guard let rankedVibes = place.stats?.visibleTopVibes, !rankedVibes.isEmpty else {
            return tags
        }

        let rankByTag = rankedVibes.enumerated().reduce(into: [VibeTag: Int]()) { ranks, item in
            ranks[item.element.vibeTag] = item.offset
        }

        return tags.enumerated()
            .sorted { lhs, rhs in
                let lhsRank = rankByTag[lhs.element] ?? Int.max
                let rhsRank = rankByTag[rhs.element] ?? Int.max

                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }

                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    private func selectedPercentageText(for tag: VibeTag) -> String {
        if let breakdown = place.stats?.visibleTopVibes.first(where: { $0.vibeTag == tag }) {
            return "\(breakdown.percentage)%"
        }

        return L10n.string("MY PICK")
    }

    private var vibeCountHeadline: String {
        let count = max(place.stats?.ratingCount ?? 0, selectedTags.isEmpty ? 0 : 1)
        return Self.countFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    private var vibeCountLabel: String {
        let count = max(place.stats?.ratingCount ?? 0, selectedTags.isEmpty ? 0 : 1)
        return L10n.string(count == 1 ? "VIBE SUBMITTED" : "VIBES SUBMITTED")
    }

    private var locationText: String {
        if !place.localityLine.isEmpty {
            return place.localityLine.uppercased()
        }

        if let country = place.country, !country.isEmpty {
            return country.uppercased()
        }

        return String(format: "%.3f, %.3f", place.latitude, place.longitude)
    }

    private var addressText: String {
        if !place.locationLine.isEmpty {
            return place.locationLine
        }

        return locationText
    }

    private static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

private struct ShareCardVibeRowModel {
    let tag: VibeTag
    let title: String
    let percentageText: String
}

private struct ShareCardVibeRow: View {
    let model: ShareCardVibeRowModel

    var body: some View {
        HStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.94))
                    .frame(width: 92, height: 92)

                Circle()
                    .fill(Color.white.opacity(0.86))
                    .frame(width: 76, height: 76)

                VibeIconImage(tag: model.tag, size: 42)
                    .foregroundStyle(model.tag.visualStyle.color)
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(width: 100, height: 100)
            .shadow(color: .black.opacity(0.14), radius: 6, y: 2)

            Text(model.title.uppercased())
                .font(.system(size: 39, weight: .black))
                .fontWidth(.condensed)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.62)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(model.percentageText)
                .font(.system(size: model.percentageText.contains("%") ? 58 : 32, weight: .black))
                .fontWidth(.condensed)
                .foregroundStyle(model.tag.visualStyle.color)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
                .frame(width: 178, height: 74, alignment: .center)
                .background(Color.white.opacity(0.92), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(model.tag.visualStyle.color.opacity(0.22), lineWidth: 2)
                }
                .shadow(color: Color.black.opacity(0.10), radius: 6, y: 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(minHeight: 124)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
        }
    }
}

private struct ShareAppStoreBadge: View {
    var width: CGFloat = 260
    var height: CGFloat = 86

    var body: some View {
        Image("DownloadOnAppStore")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height, alignment: .leading)
    }
}

private struct ShareQRCodeView: View {
    let url: URL
    var size: CGFloat = 220
    var codeSize: CGFloat = 174

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .frame(width: size, height: size)

            if let image = Self.qrImage(for: url) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: codeSize, height: codeSize)
            } else {
                Image(systemName: "qrcode")
                    .font(.system(size: codeSize * 0.8, weight: .regular))
                    .foregroundStyle(VibeDesign.brandBlue)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(VibeDesign.brandYellow, lineWidth: 6)
        }
    }

    private static let context = CIContext()

    private static func qrImage(for url: URL) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
