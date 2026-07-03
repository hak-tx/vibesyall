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

struct AppMenuSheet: View {
    let hasConfirmedAccount: Bool
    let onSignUp: () -> Void
    let onDeleteAccount: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("VIBES Y'ALL")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(VibeDesign.primaryText)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(VibeDesign.secondaryText)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.045), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close menu")
            }

            Text("Map-first place vibes. No account needed to explore or submit.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(VibeDesign.secondaryText)

            VStack(spacing: 10) {
                Button {
                    dismiss()
                    onSignUp()
                } label: {
                    MenuActionRow(
                        icon: hasConfirmedAccount ? "checkmark.seal.fill" : "person.crop.circle.badge.plus",
                        title: hasConfirmedAccount ? "Account saved" : "Create account",
                        subtitle: hasConfirmedAccount ? "Your confirmed account is active on this device." : "Available after 10 vibed places so your history can follow you.",
                        tint: VibeDesign.brandBlue,
                        showsChevron: !hasConfirmedAccount
                    )
                }
                .buttonStyle(.plain)
                .disabled(hasConfirmedAccount)

                Divider()
                    .padding(.leading, 48)

                Button {
                    openURL(AppConfig.privacyPolicyURL)
                } label: {
                    MenuActionRow(
                        icon: "hand.raised.fill",
                        title: "Privacy Policy",
                        tint: .gray
                    )
                }
                .buttonStyle(.plain)

                Button {
                    openURL(AppConfig.termsURL)
                } label: {
                    MenuActionRow(
                        icon: "doc.text.fill",
                        title: "Terms of Use",
                        tint: .gray
                    )
                }
                .buttonStyle(.plain)

                Button {
                    openURL(AppConfig.supportURL)
                } label: {
                    MenuActionRow(
                        icon: "questionmark.circle.fill",
                        title: "Support",
                        tint: .gray
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 48)

                Button(role: .destructive) {
                    dismiss()
                    onDeleteAccount()
                } label: {
                    MenuActionRow(
                        icon: "trash.fill",
                        title: "Delete account",
                        subtitle: "Delete the optional account tied to this device and email.",
                        tint: .red
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .background(VibeDesign.sheetBackground)
    }
}

struct AccountDeletionSheet: View {
    @ObservedObject var viewModel: VibeMapViewModel

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEmailFocused: Bool
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        normalizedEmail.contains("@") && !isSubmitting && statusMessage == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Delete account")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(VibeDesign.primaryText)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(VibeDesign.secondaryText)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.045), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            Text("This removes the optional email account linked to this device. Anonymous vibe events remain private and continue to count only in aggregate place stats.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(VibeDesign.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

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

                    Text(statusMessage == nil ? "Delete account" : "Deleted")
                        .font(.headline.weight(.black))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(canSubmit ? Color.red : Color.red.opacity(0.30), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)

            Button {
                dismiss()
            } label: {
                Text(statusMessage == nil ? "Cancel" : "Done")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(VibeDesign.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .background(VibeDesign.sheetBackground)
    }

    @MainActor
    private func submit() async {
        guard canSubmit else { return }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let response = try await viewModel.requestAccountDeletion(email: normalizedEmail)
            statusMessage = response.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct MenuActionRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let tint: Color
    var showsChevron = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 2) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(VibeDesign.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(VibeDesign.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 10)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(VibeDesign.secondaryText.opacity(0.65))
            }
        }
        .contentShape(Rectangle())
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
