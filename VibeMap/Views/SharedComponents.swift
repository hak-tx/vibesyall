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

    init(onSwipeDown: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.onSwipeDown = onSwipeDown
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
                        guard value.translation.height > 24,
                              abs(value.translation.width) < 70 else {
                            return
                        }

                        onSwipeDown?()
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
        .confirmationDialog("Open directions", isPresented: $isChoosingMapApp, titleVisibility: .visible) {
            Button("Apple Maps") {
                MapDirectionsLauncher.openAppleMaps(for: place)
            }

            Button("Google Maps") {
                MapDirectionsLauncher.openGoogleMaps(for: place)
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(place.name)
        }
        .accessibilityLabel("Directions to \(place.name)")
    }
}

@MainActor
private enum MapDirectionsLauncher {
    static func openAppleMaps(for place: VibePlace) {
        Task {
            let mapItem = await appleMapItem(for: place)
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        }
    }

    static func openGoogleMaps(for place: VibePlace) {
        guard let webURL = googleWebDirectionsURL(for: place) else {
            return
        }

        if let appURL = googleAppDirectionsURL(for: place),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }

        UIApplication.shared.open(webURL)
    }

    private static func appleMapItem(for place: VibePlace) async -> MKMapItem {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = place.directionsSearchQuery
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

    private static func googleAppDirectionsURL(for place: VibePlace) -> URL? {
        var components = URLComponents(string: "comgooglemaps://")
        components?.queryItems = [
            URLQueryItem(name: "daddr", value: place.directionsSearchQuery),
            URLQueryItem(name: "directionsmode", value: "driving")
        ]
        return components?.url
    }

    private static func googleWebDirectionsURL(for place: VibePlace) -> URL? {
        var components = URLComponents(string: "https://www.google.com/maps/dir/")
        var queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "destination", value: place.directionsSearchQuery),
            URLQueryItem(name: "travelmode", value: "driving")
        ]

        if place.provider?.localizedCaseInsensitiveContains("google") == true,
           let providerPlaceId = place.providerPlaceId,
           !providerPlaceId.isEmpty {
            queryItems.append(URLQueryItem(name: "destination_place_id", value: providerPlaceId))
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
    var directionsSearchQuery: String {
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
            .frame(width: 1080, height: 1350)
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

    private func shareText(for tags: [VibeTag]) -> String {
        let vibeText = tags.isEmpty ? "good vibes" : tags.map(\.rawValue).joined(separator: " + ")
        return "\(place.name) has \(vibeText) on VIBES Y'ALL."
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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.96, blue: 0.88),
                    Color(red: 0.98, green: 0.97, blue: 0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 44) {
                header

                VStack(alignment: .leading, spacing: 20) {
                    Text(place.name)
                        .font(.system(size: 74, weight: .black))
                        .foregroundStyle(VibeDesign.primaryText)
                        .lineLimit(3)
                        .minimumScaleFactor(0.72)

                    if !place.locationLine.isEmpty {
                        Text(place.locationLine)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(VibeDesign.linkText)
                            .lineLimit(2)
                    }

                    if let category = place.displayCategory {
                        Label(category, systemImage: "tag.fill")
                            .font(.system(size: 29, weight: .bold))
                            .foregroundStyle(VibeDesign.secondaryText)
                    }
                }

                selectedVibesSection

                communitySection

                Spacer(minLength: 0)

                Text("Real places. Real vibes.")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(VibeDesign.primary.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(76)
        }
        .clipShape(RoundedRectangle(cornerRadius: 62, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .center) {
            Image("BrandLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 178, height: 178)
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.60), lineWidth: 2)
                }

            Spacer()

            if let topVibe = place.stats?.visibleTopVibes.first {
                ShareMetricPill(
                    title: "Top vibe",
                    value: "\(topVibe.vibeTag.rawValue) \(topVibe.percentage)%",
                    vibe: topVibe.vibeTag
                )
            } else {
                ShareMetricPill(title: "Vibe count", value: "Be first", vibe: nil)
            }
        }
    }

    @ViewBuilder
    private var selectedVibesSection: some View {
        if selectedTags.isEmpty {
            ShareSection(title: "Check this place out") {
                Text("Send it to someone who needs a good spot.")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(VibeDesign.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 28)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
        } else {
            ShareSection(title: "My vibe") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(selectedTags) { tag in
                        ShareVibePill(tag: tag)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var communitySection: some View {
        ShareSection(title: "Community") {
            if let stats = place.stats, stats.ratingCount > 0 {
                VStack(spacing: 14) {
                    HStack {
                        Label(vibeCountText(stats.ratingCount), systemImage: "person.2.fill")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(VibeDesign.primary)

                        Spacer()
                    }

                    ForEach(stats.visibleTopVibes.prefix(3)) { breakdown in
                        HStack(spacing: 18) {
                            Image(systemName: breakdown.vibeTag.visualStyle.symbolName)
                                .font(.system(size: 30, weight: .black))
                                .foregroundStyle(breakdown.vibeTag.visualStyle.color)
                                .frame(width: 42)

                            Text(breakdown.vibeTag.rawValue)
                                .font(.system(size: 34, weight: .black))
                                .foregroundStyle(VibeDesign.primaryText)

                            Spacer()

                            Text("\(breakdown.percentage)%")
                                .font(.system(size: 36, weight: .black))
                                .foregroundStyle(breakdown.vibeTag.visualStyle.color)
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 20)
                        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                }
            } else {
                Text("No community votes yet.")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(VibeDesign.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 28)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
        }
    }

    private func vibeCountText(_ count: Int) -> String {
        let countText = Self.countFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
        return "\(countText) \(count == 1 ? "vibe" : "vibes") submitted"
    }

    private static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

private struct ShareSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title.uppercased())
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(VibeDesign.secondaryText)

            content
        }
    }
}

private struct ShareMetricPill: View {
    let title: String
    let value: String
    let vibe: VibeTag?

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(VibeDesign.secondaryText)

            HStack(spacing: 12) {
                if let vibe {
                    Image(systemName: vibe.visualStyle.symbolName)
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(vibe.visualStyle.color)
                }

                Text(value)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(VibeDesign.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct ShareVibePill: View {
    let tag: VibeTag

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tag.visualStyle.color.opacity(0.16))
                    .frame(width: 54, height: 54)

                Image(systemName: tag.visualStyle.symbolName)
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(tag.visualStyle.color)
            }

            Text(tag.rawValue)
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(VibeDesign.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(tag.visualStyle.color.opacity(0.20), lineWidth: 2)
        }
    }
}
