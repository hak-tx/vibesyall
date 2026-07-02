import SwiftUI

struct SelectedPlacePanel: View {
    @ObservedObject var viewModel: VibeMapViewModel

    var body: some View {
        BottomPanel {
            if let place = viewModel.selectedPlace {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(place.name)
                                    .font(.title2.weight(.black))
                                    .foregroundStyle(VibeDesign.primaryText)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.86)
                                    .fixedSize(horizontal: false, vertical: true)

                                if !place.locationLine.isEmpty {
                                    AddressDirectionsLink(place: place)
                                }
                            }

                            Spacer()

                            Button {
                                viewModel.clearSelection()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(VibeDesign.secondaryText)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Close spot")
                        }

                        PlaceMetaActionRow(place: place)
                    }

                    if viewModel.canRevealCommunity(for: place) {
                        CompactPlaceStatsView(place: place)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(VibeDesign.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(VibeDesign.hairline, lineWidth: 1)
                            }
                    } else if let signal = place.primaryDiscoverySignal, signal != .firstToVibe {
                        VStack(alignment: .leading, spacing: 8) {
                            DiscoverySignalPill(signal: signal)
                            Text(signal.message)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(VibeDesign.secondaryText)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(VibeDesign.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(VibeDesign.hairline, lineWidth: 1)
                        }
                    }

                    HStack(spacing: 10) {
                        SharePlaceButton(place: place)

                        Button {
                            viewModel.openRating()
                        } label: {
                            Label(place.myRating == nil ? "Add vibe" : "Edit vibes", systemImage: "hand.thumbsup.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(VibeDesign.primary)
                    }
                }
            }
        }
    }
}
