# VIBES Y'ALL App Store Submission Checklist

## App Store Connect URLs

- Marketing URL: `https://vibesyall.com`
- Privacy Policy URL: `https://vibesyall.com/privacy`
- Support URL: `https://vibesyall.com/support`
- Terms URL: `https://vibesyall.com/terms`
- Production API: `https://api.vibesyall.com`

## App Information

- Name: `VIBES Y'ALL`
- Bundle ID: `com.brianhakel.vibemap`
- SKU suggestion: `vibes-yall-ios`
- Primary category suggestion: `Lifestyle`
- Secondary category suggestion: `Travel`
- Age rating expectation: likely `4+`, assuming the questionnaire confirms no unrestricted web access, no user-written reviews, no photos, no public profiles, no gambling, and no mature content.

## Version Information Draft

- Subtitle: `Find places by the vibe`
- Promotional text: `No stars. No comments. Just quick human vibes for real places.`
- Keywords: `maps,places,travel,food,restaurants,local,discovery,reviews,vibes`

Description:

```text
VIBES Y'ALL is a map-first way to discover places by how they feel.

Tap a real place, pick one to three quick vibe labels, and see what the community thinks without star ratings, comments, or noisy written reviews.

Use it to find places that are Changed my Life, Fire, Worth the Drive, Iconic, Hidden Gem, Underrated, Mid, Chaos, Overrated, Tourist Trap, Needs Prayer, or Emotionally Damaging.

Start anonymously. After you contribute enough places, you can optionally add an email so your vibe history can stay with you if you switch devices.
```

Review notes:

```text
VIBES Y'ALL is a map-first place discovery app. It lets people tap or search real-world places and submit one to three predefined vibe tags. The value is quick structured place sentiment without star ratings, comments, photos, public profiles, followers, messaging, or paid content.

No account, purchase, subscription, sample file, or demo credential is required for the main app flow.

App Review sign-in:
The main app is free to use anonymously. VIBES Y'ALL also includes an optional account backup flow after 10 submitted places. For App Review, a dedicated reviewer login is available so the optional account state can be tested without waiting for email delivery:

Review login URL: https://vibesyall.com/account/review-login
Username: appreview@vibesyall.com
Password: use the password entered in the App Review Sign-in Information field.

Open the review login URL in Safari on the test device, enter the credentials, then tap "Open the app" to return to VIBES Y'ALL with a verified review account session.

Reviewer flow:
1. Launch the app.
2. Allow Location While Using when prompted, or deny it and use search manually.
3. Use the search bar or tap an existing map pin / Apple Maps point of interest.
4. Select one to three vibe tags.
5. Tap Submit Vibes.
6. Review the confirmation card, community vibe summary, and optional share flow.
7. Use the What's Nearby sheet to explore other nearby places.

Optional account note:
After a device has submitted 10 places, the app may offer optional email backup so a user can preserve vibe history across devices. This is not required to access the app or test the core flow. App Review can use the reviewer login above to test the optional account state.

Permissions:
The app requests Location While Using to center the map and show nearby places. Users can still search manually if location permission is denied. The app does not request camera, photo library, contacts, microphone, or tracking permission.

User-generated content:
The only submitted user content is selection from fixed predefined vibe tags. There are no written reviews, comments, photos, public profiles, private messages, or follower features in V1. Reports and support are available through https://vibesyall.com/support.

External services:
Apple MapKit/Apple Maps for maps, place search, point-of-interest details, and directions. Cloudflare Workers and Cloudflare D1 for the VIBES Y'ALL API, aggregate vibe counts, anonymous device-based duplicate prevention, and optional email confirmation. No payment processors, subscription services, AI services, or ad networks are used.

Availability:
The app is US-first for initial testing but works wherever Apple Maps place search and the VIBES Y'ALL API are available. There are no region-specific feature, content, or regulatory differences in V1.

Encryption:
The app uses standard platform HTTPS networking only and does not implement proprietary encryption. Export compliance is set accordingly.
```

## App Privacy Answers

Use the app privacy questionnaire to disclose:

- Contact Info: Email Address, collected only if the user optionally creates an account, used for app functionality, not tracking.
- Location: Precise Location, used to show nearby places and map results, not tracking.
- Identifiers: Device ID, collected as a hashed app-specific anonymous device identifier, used to prevent duplicate place votes and allow edits, not tracking.
- User Content: Other User Content, limited to predefined vibe tag selections, used for app functionality and aggregate community results, not tracking.

The app does not collect names, phone numbers, contacts, photos, comments, star ratings, advertising identifiers, or payment information in V1.

## Export Compliance

`ITSAppUsesNonExemptEncryption` is set to `false` in `VibeMap/Resources/Info.plist`. The app uses standard Apple/platform networking only and does not implement proprietary encryption.

## Remaining Before First Review Submission

- Upload required iPhone screenshots in App Store Connect.
- Attach a physical-device screen recording to the App Review reply or provide a review-accessible link to it.
- Add the exact device model(s) and iOS version(s) used for physical-device testing in the App Review reply.
- Complete the App Privacy questionnaire so it matches this file and `VibeMap/Resources/PrivacyInfo.xcprivacy`.
- Complete the Age Rating questionnaire.
- Select pricing/availability.
- Add the final build from TestFlight to the app version.
- Confirm the support/privacy/terms links return `200` in App Store Connect.

## Guideline 2.1 Rejection Response

Apple asked for additional information under Guideline 2.1. The app does not appear to have been rejected for a specific crash or product defect in the screenshot; the blocking item is the missing reviewer context and physical-device recording.

Before resubmitting:

- Record the app on a physical iPhone running the latest available iOS version.
- Start the recording from launching the app.
- Show the location permission prompt if it appears.
- Show the normal flow: search or tap a place, select one to three vibes, submit, view the community results, and open the share sheet.
- If available, show the What's Nearby card and map filters briefly.
- Note the exact device model and iOS version used.

Copy/paste this into the App Review reply and Notes field, replacing the bracketed line:

```text
Hello App Review,

Thank you for the review. I added the requested App Review Information below.

1. Screen recording
I have attached a physical-device screen recording that starts with launching the app and shows the typical core flow: location/map access, searching or selecting a place, choosing one to three vibe tags, submitting, seeing the community summary, and opening the share flow.

2. Device models and operating systems tested
[Brian: add exact physical device model and iOS version here, for example: iPhone 15 Pro running iOS 26.0.]

3. App purpose and target audience
VIBES Y'ALL is a map-first place discovery app for people who want a quick way to discover restaurants, venues, attractions, stores, and other real-world places by how the community describes the vibe. Users select predefined vibe tags instead of writing reviews or using star ratings. The app is intended for general consumers looking for nearby places and for lightweight place sentiment discovery.

4. Setup and access instructions
No login, paid purchase, subscription, sample file, or demo credential is required for the main app.

App Review sign-in:
The main app can be reviewed without an account. VIBES Y'ALL also includes an optional account backup flow after 10 submitted places. To test the optional account state without waiting for email confirmation, use:

Review login URL: https://vibesyall.com/account/review-login
Username: appreview@vibesyall.com
Password: use the password in App Store Connect Sign-in Information.

Open that URL in Safari on the review device, enter the credentials, then tap "Open the app" to return to VIBES Y'ALL with a verified review account session.

Reviewer flow:
1. Launch VIBES Y'ALL.
2. Allow Location While Using when prompted, or deny it and use search manually.
3. Use the search bar or tap an existing map pin / Apple Maps point of interest.
4. Select one to three vibe tags.
5. Tap Submit Vibes.
6. Review the confirmation card, community vibe summary, and optional share flow.
7. Use the What's Nearby sheet to explore nearby places.

Optional account note:
After a device has submitted 10 places, the app may offer optional email backup so a user can preserve vibe history across devices. This is not required to use or review the core app flow. The reviewer login above creates the same verified account session for testing.

5. External services, tools, and platforms
- Apple MapKit / Apple Maps: map display, place search, point-of-interest details, and directions.
- Cloudflare Workers and Cloudflare D1: VIBES Y'ALL API, aggregate vibe counts, anonymous device-based duplicate prevention, optional email confirmation, and support/marketing pages.
- Apple App Store / TestFlight services for distribution.

The app does not use payment processors, subscriptions, ad networks, third-party analytics SDKs, AI services, comments, written reviews, photos, public profiles, followers, messaging, or social-network features.

6. Regional differences
There are no region-specific feature, content, or regulatory differences in V1. The app is US-first for initial testing, but the map/search experience works wherever Apple Maps place search and the VIBES Y'ALL API are available.

7. Regulated industry or protected third-party material
The app is not in a regulated industry and does not include protected third-party material beyond Apple MapKit / Apple Maps functionality available through iOS APIs. VIBES Y'ALL stores user selections from predefined vibe tags only; there are no comments, photos, or user-uploaded media.
```

## Review Risks To Close Next

Apple's current guideline 5.1.1 says apps that support account creation must also offer account deletion in the app. VIBES Y'ALL currently keeps the core app anonymous, but it has an optional email backup flow after 10 submitted places.

Before the next full App Store review, choose one of these:

- Add in-app account deletion for the optional email backup account.
- Temporarily disable optional account creation in the App Store build until the deletion flow is ready.

This is not the stated reason for the current 2.1 rejection, but it is a likely follow-up review issue if Apple reaches or asks about the optional signup flow.
