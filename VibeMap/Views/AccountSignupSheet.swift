import SwiftUI

struct AccountSignupSheet: View {
    @ObservedObject var viewModel: VibeMapViewModel
    let prompt: AccountSignupPrompt

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEmailFocused: Bool
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    private var benefits: [String] {
        prompt.eligibility.benefits.isEmpty ? AccountBenefit.defaultBenefits : prompt.eligibility.benefits
    }

    private var canSubmit: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).contains("@") && !isSubmitting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Save your vibes")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(VibeDesign.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(prompt.eligibility.progressText)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(VibeDesign.secondaryText)
                }

                Spacer(minLength: 12)

                Button {
                    viewModel.dismissAccountSignupPrompt()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(VibeDesign.secondaryText)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.045), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Maybe later")
            }

            VStack(alignment: .leading, spacing: 9) {
                ForEach(benefits.prefix(4), id: \.self) { benefit in
                    BenefitRow(text: benefit)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                TextField("Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isEmailFocused)
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(VibeDesign.hairline, lineWidth: 1)
                    }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(VibeDesign.secondaryText)
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }

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

                    Text(statusMessage == nil ? "Send confirmation" : "Sent")
                        .font(.headline.weight(.black))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(canSubmit ? VibeDesign.primary : VibeDesign.primary.opacity(0.35), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit || statusMessage != nil)

            Button {
                viewModel.dismissAccountSignupPrompt()
                dismiss()
            } label: {
                Text(statusMessage == nil ? "Maybe later" : "Done")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(VibeDesign.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 18)
        .background(VibeDesign.sheetBackground)
    }

    @MainActor
    private func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let response = try await viewModel.requestAccountSignup(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            statusMessage = response.emailSent ? response.message : "Confirmation is ready. Email delivery still needs the Cloudflare email binding."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct BenefitRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(VibeDesign.brandBlue)
                .padding(.top, 1)

            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VibeDesign.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
