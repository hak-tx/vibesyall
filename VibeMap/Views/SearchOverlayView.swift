import SwiftUI

struct SearchOverlayView: View {
    @ObservedObject var viewModel: VibeMapViewModel
    @Binding var isSearchFocused: Bool
    let onMenuTap: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    searchField

                    Button(action: onMenuTap) {
                        BrandMenuButtonLabel()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open VIBES Y'ALL menu")
                }

                vibeFilters(containerWidth: geometry.size.width)

                if shouldShowResults {
                    resultsPanel(maxHeight: resultsMaxHeight(in: geometry))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFieldFocused = false
                    isSearchFocused = false
                }
                .font(.headline)
                .foregroundStyle(VibeDesign.primary)
            }
        }
        .onChange(of: isFieldFocused) { _, focused in
            isSearchFocused = focused
        }
        .onChange(of: isSearchFocused) { _, focused in
            if isFieldFocused != focused {
                isFieldFocused = focused
            }
        }
        .task(id: viewModel.searchQuery) {
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            await viewModel.searchPlaces()
        }
    }

    private func resultsPanel(maxHeight: CGFloat) -> some View {
        let results = viewModel.filteredSearchResults

        return VStack(spacing: 0) {
            if !results.isEmpty {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { result in
                            Button {
                                isFieldFocused = false
                                isSearchFocused = false
                                Task {
                                    await viewModel.selectSearchResult(result)
                                }
                            } label: {
                                SearchResultRow(result: result)
                            }
                            .buttonStyle(.plain)

                            if result.id != results.last?.id {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .frame(maxHeight: maxHeight)
            } else if viewModel.didFilterSearchResultsToEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("No results match those vibes yet.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(VibeDesign.primaryText)

                    Text("Clear a chip or try another nearby search.")
                        .font(.caption)
                        .foregroundStyle(VibeDesign.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }

            if let searchError = viewModel.searchError {
                Text(searchError)
                    .font(.footnote)
                    .foregroundStyle(VibeDesign.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .background(VibeDesign.overlayBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.46), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 14, y: 8)
    }

    private func resultsMaxHeight(in geometry: GeometryProxy) -> CGFloat {
        let controlsHeight: CGFloat = 48 + 8 + 30 + 8
        let reservedBottom: CGFloat = isFieldFocused ? 330 : 150
        let availableHeight = geometry.size.height - 12 - controlsHeight - reservedBottom

        if isSearchFocused {
            return min(max(availableHeight, 180), 340)
        }

        return min(max(availableHeight, 220), 520)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(VibeDesign.brandYellow.opacity(0.92))

            ZStack(alignment: .leading) {
                if viewModel.searchQuery.isEmpty {
                    Text("Search a place...")
                        .foregroundStyle(VibeDesign.brandYellow.opacity(0.70))
                        .lineLimit(1)
                }

                TextField("", text: $viewModel.searchQuery)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .focused($isFieldFocused)
                    .foregroundStyle(.white)
                    .tint(VibeDesign.brandYellow)
                    .onSubmit {
                        isFieldFocused = false
                        isSearchFocused = false
                        Task {
                            await viewModel.searchPlaces()
                        }
                    }
            }

            if viewModel.isSearching {
                ProgressView()
                    .controlSize(.small)
                    .tint(VibeDesign.brandYellow)
            } else if isFieldFocused {
                Button {
                    isFieldFocused = false
                    isSearchFocused = false
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(VibeDesign.brandYellow.opacity(0.86))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hide keyboard")
            }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clearSearch()
                    isFieldFocused = false
                    isSearchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(VibeDesign.brandYellow.opacity(0.86))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(VibeDesign.brandBlue.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(VibeDesign.brandYellow.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
    }

    @ViewBuilder
    private func vibeFilters(containerWidth: CGFloat) -> some View {
        if usesExpandedFilterLayout(containerWidth: containerWidth) {
            HStack(spacing: 8) {
                filterButton(title: "All", vibe: nil, isExpanded: true)

                ForEach(VibeTag.bestToWorst(viewModel.allowedVibes)) { vibe in
                    filterButton(title: expandedFilterTitle(for: vibe), vibe: vibe, isExpanded: true)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    filterButton(title: "All", vibe: nil, isExpanded: false)

                    ForEach(VibeTag.bestToWorst(viewModel.allowedVibes)) { vibe in
                        filterButton(title: vibe.mapLabel, vibe: vibe, isExpanded: false)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func filterButton(title: String, vibe: VibeTag?, isExpanded: Bool) -> some View {
        Button {
            viewModel.setVibeFilter(vibe)
        } label: {
            VibeFilterChip(
                title: title,
                vibe: vibe,
                isSelected: filterIsSelected(vibe),
                isExpanded: isExpanded
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: isExpanded ? .infinity : nil)
    }

    private func filterIsSelected(_ vibe: VibeTag?) -> Bool {
        if let vibe {
            return viewModel.selectedVibeFilters.contains(vibe)
        }

        return !viewModel.hasActiveVibeFilters
    }

    private func usesExpandedFilterLayout(containerWidth: CGFloat) -> Bool {
        horizontalSizeClass == .regular && containerWidth >= 700
    }

    private func expandedFilterTitle(for vibe: VibeTag) -> String {
        switch vibe {
        case .changedMyLife:
            "Changed\nMy Life"
        case .worthTheDrive:
            "Worth the\nDrive"
        case .hiddenGem:
            "Hidden\nGem"
        case .touristTrap:
            "Tourist\nTrap"
        case .needsPrayer:
            "Needs\nPrayer"
        case .emotionallyDamaging:
            "Emotionally\nDamaging"
        default:
            vibe.rawValue
        }
    }

    private var shouldShowResults: Bool {
        !viewModel.filteredSearchResults.isEmpty ||
            viewModel.didFilterSearchResultsToEmpty ||
            viewModel.searchError != nil ||
            viewModel.isSearching
    }
}

private struct BrandMenuButtonLabel: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("BrandLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.94))
                        .frame(width: 54, height: 54)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(.white.opacity(0.96), lineWidth: 2.5)
                }

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(VibeDesign.brandYellow)
                .frame(width: 18, height: 18)
                .background(VibeDesign.brandBlue, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.96), lineWidth: 1.5)
                }
                .offset(x: 5, y: 7)
        }
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
    }
}

private struct VibeFilterChip: View {
    let title: String
    let vibe: VibeTag?
    let isSelected: Bool
    var isExpanded = false

    var body: some View {
        HStack(spacing: isExpanded ? 4 : 5) {
            Image(systemName: symbolName)
                .font(.system(size: iconSize, weight: .black))
                .foregroundStyle(isSelected ? .white : iconColor)
                .frame(width: iconFrameWidth)

            Text(title)
                .font(textFont)
                .foregroundStyle(isSelected ? .white : VibeDesign.primaryText.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineLimit(isExpanded ? 2 : 1)
                .minimumScaleFactor(isExpanded ? 0.68 : 0.78)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: isExpanded ? .infinity : nil)
        .frame(height: chipHeight)
        .background(isSelected ? VibeDesign.primary : VibeDesign.overlayBackground, in: Capsule())
        .overlay {
            Capsule()
                .stroke(isSelected ? Color.clear : VibeDesign.brandBlue.opacity(0.34), lineWidth: 1)
        }
        .shadow(color: isSelected ? VibeDesign.pressedShadow : .black.opacity(0.06), radius: 8, y: 3)
    }

    private var symbolName: String {
        vibe?.visualStyle.symbolName ?? "circle.grid.2x2.fill"
    }

    private var iconColor: Color {
        vibe?.visualStyle.color ?? VibeDesign.primary
    }

    private var textFont: Font {
        if isExpanded {
            return .system(size: expandedTextSize, weight: .heavy)
        }

        if title == "Damaging" {
            return .system(size: 10.4, weight: .heavy)
        }

        return .caption.weight(.heavy)
    }

    private var expandedTextSize: CGFloat {
        let compactLength = title.replacingOccurrences(of: "\n", with: " ").count

        if compactLength >= 20 {
            return 8.8
        }

        if compactLength >= 14 {
            return 9.4
        }

        return 10.4
    }

    private var iconSize: CGFloat {
        isExpanded ? 11.5 : 10
    }

    private var iconFrameWidth: CGFloat {
        isExpanded ? 14 : 12
    }

    private var horizontalPadding: CGFloat {
        isExpanded ? 6 : 9
    }

    private var chipHeight: CGFloat {
        isExpanded ? 42 : 30
    }
}

private struct SearchResultRow: View {
    let result: PlaceSearchResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            resultIcon

            VStack(alignment: .leading, spacing: 3) {
                Text(result.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(VibeDesign.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if !result.locationLine.isEmpty {
                    Text(result.locationLine)
                        .font(.caption)
                        .foregroundStyle(VibeDesign.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if let topVibe = result.topVibe {
                    HStack(spacing: 4) {
                        Image(systemName: topVibe.vibeTag.visualStyle.symbolName)
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(topVibe.vibeTag.visualStyle.color)

                        Text(topVibe.vibeTag.rawValue)
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(VibeDesign.primaryText)
                            .lineLimit(1)

                        Text("\(topVibe.percentage)%")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(topVibe.vibeTag.visualStyle.color)

                        Text("· \(result.vibeCount) \(result.vibeCount == 1 ? "vibe" : "vibes")")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(VibeDesign.secondaryText)
                    }
                    .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(0)

            if let distanceText = result.distanceText {
                Text(distanceText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(VibeDesign.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.045), in: Capsule())
                    .frame(minWidth: 64, alignment: .trailing)
                    .layoutPriority(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, result.hasCommunityVibes ? 10 : 12)
    }

    @ViewBuilder
    private var resultIcon: some View {
        if let topVibe = result.topVibe {
            ZStack {
                Circle()
                    .fill(topVibe.vibeTag.visualStyle.color.opacity(0.16))

                Image(systemName: topVibe.vibeTag.visualStyle.symbolName)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(topVibe.vibeTag.visualStyle.color)
            }
            .frame(width: 28, height: 28)
        } else {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(VibeDesign.primary)
                .frame(width: 28)
        }
    }
}
