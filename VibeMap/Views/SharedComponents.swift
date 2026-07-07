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
        switch self {
        case .dark:
            "Dark"
        case .standard:
            "Standard"
        case .satellite:
            "Satellite"
        }
    }

    var shortLabel: String {
        switch self {
        case .dark:
            "Dark"
        case .standard:
            "Map"
        case .satellite:
            "Sat"
        }
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
            .frame(height: 27)
            .overlay {
                Capsule()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: 42, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        guard abs(value.translation.width) < 70 else {
                            return
                        }

                        if value.translation.height > 24 {
                            onSwipeDown?()
                        } else if value.translation.height < -24 {
                            onSwipeUp?()
                        }
                    }
            )
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
            return "Be the first"
        }

        let countText = Self.countFormatter.string(from: NSNumber(value: ratingCount)) ?? "\(ratingCount)"
        let noun = ratingCount == 1 ? "vibe" : "vibes"
        return compact ? "\(countText) \(noun)" : "\(countText) \(noun) submitted"
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

private struct CommunityPulseItem: View {
    let breakdown: VibeBreakdown
    var compact = true

    var body: some View {
        HStack(spacing: compact ? 4 : 5) {
            Image(systemName: breakdown.vibeTag.visualStyle.symbolName)
                .font(.system(size: compact ? 9 : 10, weight: .black))
                .foregroundStyle(breakdown.vibeTag.visualStyle.color)
                .frame(width: compact ? 12 : 14)

            Text(breakdown.vibeTag.rawValue)
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
        Label(category, systemImage: symbolName)
            .font(.caption.weight(.bold))
            .foregroundStyle(VibeDesign.secondaryText)
            .lineLimit(1)
            .fixedSize()
    }

    private var symbolName: String {
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
        Label(compact ? signal.shortLabel : signal.rawValue, systemImage: iconName)
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
        }
    }
}

struct AddressDirectionsLink: View {
    let place: VibePlace
    @State private var isChoosingMapApp = false

    var body: some View {
        Button {
            isChoosingMapApp = true
        } label: {
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
        .buttonStyle(.plain)
        .confirmationDialog("Learn More", isPresented: $isChoosingMapApp, titleVisibility: .visible) {
            if !place.isGoogleProviderPlace {
                Button("Apple Maps") {
                    MapPlaceLauncher.openAppleMaps(for: place)
                }
            }

            Button("Google Maps") {
                MapPlaceLauncher.openGoogleMaps(for: place)
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Contact, directions, pictures, etc.")
        }
        .accessibilityLabel("Open \(place.name) in Maps")
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

    @State private var sharePayload: VibeSharePayload?
    @State private var isRendering = false

    var body: some View {
        Button {
            Task {
                await prepareSharePayload()
            }
        } label: {
            Label(title, systemImage: isRendering ? "hourglass" : "square.and.arrow.up")
                .font(buttonFont)
                .frame(maxWidth: isProminent ? .infinity : nil)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isProminent ? .white : VibeDesign.primary)
        .padding(.horizontal, horizontalPadding)
        .frame(height: buttonHeight)
        .background(isProminent ? VibeDesign.primary : VibeDesign.controlBackground, in: Capsule())
        .overlay {
            Capsule()
                .stroke(isProminent ? Color.white.opacity(0.16) : VibeDesign.hairline, lineWidth: 1)
        }
        .shadow(color: isProminent ? VibeDesign.pressedShadow : .black.opacity(0.05), radius: isProminent ? 10 : 7, y: 3)
        .disabled(isRendering)
        .sheet(item: $sharePayload) { payload in
            ShareActivityView(activityItems: payload.activityItems)
        }
        .accessibilityLabel("Share \(place.name)")
    }

    private var buttonFont: Font {
        if isProminent {
            return .headline.weight(.black)
        }

        return isCompact ? .caption.weight(.black) : .subheadline.weight(.bold)
    }

    private var horizontalPadding: CGFloat {
        if isProminent {
            return 16
        }

        return isCompact ? 10 : 12
    }

    private var buttonHeight: CGFloat {
        if isProminent {
            return 46
        }

        return isCompact ? 30 : 40
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
            text: shareText(for: tags),
            url: AppConfig.appStoreURL
        )
    }

    private var effectiveSelectedTags: [VibeTag] {
        let normalizedTags = VibeTag.normalizedSelection(selectedTags)
        if !normalizedTags.isEmpty {
            return normalizedTags
        }

        return place.myRating?.selectedVibeTags ?? []
    }

    private func shareText(for tags: [VibeTag]) -> String {
        let vibeText = tags.isEmpty ? "good vibes" : tags.map(\.rawValue).joined(separator: " + ")
        return "\(place.name) has \(vibeText) on VIBES Y'ALL."
    }
}

private struct VibeSharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
    let text: String
    let url: URL

    var activityItems: [Any] {
        [image, text, url]
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
            VibeDesign.brandBlue,
            Color(red: 0.02, green: 0.12, blue: 0.31)
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

            HStack(spacing: 46) {
                leftColumn
                    .frame(width: 875, alignment: .leading)

                Rectangle()
                    .fill(VibeDesign.brandBlue.opacity(0.15))
                    .frame(width: 2)
                    .padding(.vertical, 8)

                rightColumn
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 78)
            .padding(.vertical, 76)
        }
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 30) {
            header

            vibePanel
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 28) {
                ZStack {
                    Circle()
                        .fill(VibeDesign.brandBlue)
                        .frame(width: 98, height: 98)

                    Image(systemName: categorySymbolName)
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(VibeDesign.brandYellow)
                }

                Text(place.name.uppercased())
                    .font(.system(size: 62, weight: .black))
                    .foregroundStyle(VibeDesign.brandBlue)
                    .lineLimit(2)
                    .minimumScaleFactor(0.58)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 18) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(VibeDesign.brandBlue)

                Text(locationText)
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(VibeDesign.brandBlue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
        }
    }

    private var vibePanel: some View {
        VStack(spacing: 0) {
            ForEach(Array(communityRows.enumerated()), id: \.offset) { index, row in
                ShareCardVibeRow(model: row)

                if index < communityRows.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.28))
                        .frame(height: 2)
                        .padding(.leading, 4)
                }
            }

            Rectangle()
                .fill(Color.white.opacity(0.28))
                .frame(height: 2)
                .padding(.leading, 4)

            HStack(spacing: 24) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 54, weight: .black))
                    .foregroundStyle(VibeDesign.brandYellow)
                    .frame(width: 92)

                Text(vibeCountHeadline)
                    .font(.system(size: 70, weight: .black))
                    .foregroundStyle(VibeDesign.brandYellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("VIBES SUBMITTED")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 0)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity, minHeight: 612, alignment: .top)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SEE IT.\nVIBE IT.\nSHARE IT.")
                .font(.system(size: 68, weight: .black))
                .foregroundStyle(VibeDesign.brandBlue)
                .lineSpacing(16)
                .lineLimit(3)
                .minimumScaleFactor(0.72)

            Rectangle()
                .fill(VibeDesign.brandYellow)
                .frame(height: 7)
                .padding(.top, 30)
                .padding(.trailing, 32)

            Spacer(minLength: 40)

            HStack(alignment: .center, spacing: 26) {
                VStack(alignment: .leading, spacing: 26) {
                    Text("GET THE APP!")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(VibeDesign.brandBlue)
                        .lineLimit(1)

                    ShareAppStoreBadge()

                    Text("Scan or tap the link to open VIBES Y'ALL.")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(VibeDesign.brandBlue.opacity(0.72))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ShareQRCodeView(url: AppConfig.appStoreURL)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var communityRows: [ShareCardVibeRowModel] {
        if let stats = place.stats, stats.ratingCount > 0 {
            return stats.visibleTopVibes.prefix(3).map {
                ShareCardVibeRowModel(tag: $0.vibeTag, title: $0.vibeTag.rawValue, percentageText: "\($0.percentage)%")
            }
        }

        let tags = VibeTag.normalizedSelection(selectedTags)
        if !tags.isEmpty {
            return tags.prefix(3).map {
                ShareCardVibeRowModel(tag: $0, title: $0.rawValue, percentageText: "MY PICK")
            }
        }

        return [
            ShareCardVibeRowModel(tag: .iconic, title: "Be first", percentageText: "VIBE IT")
        ]
    }

    private var vibeCountHeadline: String {
        let count = max(place.stats?.ratingCount ?? 0, selectedTags.isEmpty ? 0 : 1)
        return Self.countFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
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

    private var categorySymbolName: String {
        let category = place.displayCategory?.lowercased() ?? ""
        let name = place.name.lowercased()
        let searchable = "\(category) \(name)"

        if searchable.contains("restaurant") ||
            searchable.contains("bar") ||
            searchable.contains("cafe") ||
            searchable.contains("coffee") ||
            searchable.contains("bbq") ||
            searchable.contains("grill") ||
            searchable.contains("kitchen") ||
            searchable.contains("pizza") {
            return "fork.knife"
        }

        if searchable.contains("park") || searchable.contains("trail") || searchable.contains("garden") {
            return "leaf.fill"
        }

        if searchable.contains("museum") || searchable.contains("gallery") {
            return "building.columns.fill"
        }

        if searchable.contains("hotel") || searchable.contains("inn") {
            return "bed.double.fill"
        }

        if searchable.contains("gas") || searchable.contains("station") {
            return "fuelpump.fill"
        }

        if searchable.contains("movie") || searchable.contains("cinema") || searchable.contains("theater") {
            return "film.fill"
        }

        if searchable.contains("shop") || searchable.contains("store") || searchable.contains("market") {
            return "bag.fill"
        }

        return "mappin.and.ellipse"
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
                    .stroke(VibeDesign.brandYellow, lineWidth: 2)
                    .frame(width: 112, height: 112)

                Image(systemName: model.tag.visualStyle.symbolName)
                    .font(.system(size: 55, weight: .black))
                    .foregroundStyle(VibeDesign.brandYellow)
            }

            Text(model.title.uppercased())
                .font(.system(size: 43, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.62)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(model.percentageText)
                .font(.system(size: model.percentageText.contains("%") ? 66 : 36, weight: .black))
                .foregroundStyle(VibeDesign.brandYellow)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
                .frame(width: 190, alignment: .trailing)
        }
        .frame(minHeight: 154)
        .padding(.horizontal, 4)
    }
}

private struct ShareAppStoreBadge: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "apple.logo")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 0) {
                Text("Download on the")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)

                Text("App Store")
                    .font(.system(size: 31, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .frame(width: 260, height: 86, alignment: .leading)
        .background(
            LinearGradient(
                colors: [VibeDesign.brandBlue, Color(red: 0.02, green: 0.09, blue: 0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }
}

private struct ShareQRCodeView: View {
    let url: URL

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .frame(width: 220, height: 220)

            if let image = Self.qrImage(for: url) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 174, height: 174)
            } else {
                Image(systemName: "qrcode")
                    .font(.system(size: 140, weight: .regular))
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
