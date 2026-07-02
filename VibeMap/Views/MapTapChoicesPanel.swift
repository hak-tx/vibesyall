import SwiftUI

struct MapTapChoicesPanel: View {
    @ObservedObject var viewModel: VibeMapViewModel

    var body: some View {
        BottomPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Text("Choose spot")
                        .font(.headline)
                        .foregroundStyle(VibeDesign.primaryText)

                    Spacer()

                    Button {
                        viewModel.clearMapTapChoices()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(VibeDesign.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close spot choices")
                }

                content
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isResolvingMapTap && viewModel.mapTapMatches.isEmpty {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)

                Text("Finding places")
                    .font(.subheadline)
                    .foregroundStyle(VibeDesign.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
        } else if let mapTapError = viewModel.mapTapError {
            Text(mapTapError)
                .font(.subheadline)
                .foregroundStyle(VibeDesign.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.mapTapMatches) { match in
                        Button {
                            Task {
                                await viewModel.selectMapTapMatch(match)
                            }
                        } label: {
                            MapTapChoiceRow(match: match)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSelectingPlace)
                    }
                }
            }
            .frame(maxHeight: 170)
        }
    }
}

private struct MapTapChoiceRow: View {
    let match: PlaceCandidateMatch

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(VibeDesign.primary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(match.candidate.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(VibeDesign.primaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(distanceText)
                        .font(.caption.weight(.medium))

                    if !match.candidate.locationLine.isEmpty {
                        Text(match.candidate.locationLine)
                            .font(.caption)
                            .foregroundStyle(VibeDesign.secondaryText)
                            .truncationMode(.middle)
                    }
                }
                .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.up")
                .font(.caption.weight(.bold))
                .foregroundStyle(VibeDesign.secondaryText.opacity(0.7))
        }
        .padding(12)
        .background(VibeDesign.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(VibeDesign.hairline, lineWidth: 1)
        }
    }

    private var distanceText: String {
        match.distanceText
    }
}
