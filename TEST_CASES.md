# UrbanEasyFlats Tenant App — Detailed Test Cases

**App:** `urabaneasy_flutter_app` (WebView wrapper for `https://urbaneasyflats.com/?type=tenant`)
**Version:** 1.0.12+12
**Platforms:** Android (primary), iOS
**Date:** 2026-04-15

---

## Table of Contents

1. [App Launch & Initialization](#1-app-launch--initialization)
2. [WebView Loading & Rendering](#2-webview-loading--rendering)
3. [Navigation Controls](#3-navigation-controls)
4. [Back Button Behaviour](#4-back-button-behaviour)
5. [Download — Direct File Downloads](#5-download--direct-file-downloads)
6. [Download — Blob / XHR / Fetch Downloads](#6-download--blob--xhr--fetch-downloads)
7. [File Upload](#7-file-upload)
8. [Network Connectivity](#8-network-connectivity)
9. [Special URL Handling (External Apps)](#9-special-url-handling-external-apps)
10. [Page Load Timeout & Error States](#10-page-load-timeout--error-states)
11. [JavaScript Injection & Web Interop](#11-javascript-injection--web-interop)
12. [App Lifecycle (Background / Foreground)](#12-app-lifecycle-background--foreground)
13. [Performance & UI/UX](#13-performance--uiux)

---

## 1. App Launch & Initialization

### TC-001 — Cold Launch (First Install)
**Priority:** Critical
**Steps:**
1. Install fresh APK on device with internet connection.
2. Tap app icon.

**Expected:**
- App launches without crash.
- `UrbanEasyFlats Tenant` label visible in header.
- Linear progress indicator appears immediately.
- WebView starts loading `https://urbaneasyflats.com/?type=tenant`.
- Page renders within 10 seconds on good WiFi.
- Progress indicator disappears once page loads.

---

### TC-002 — Cold Launch (No Internet)
**Priority:** Critical
**Steps:**
1. Turn off WiFi and mobile data.
2. Launch the app cold.

**Expected:**
- App launches without crash.
- "No internet connection" error message shown instead of WebView.
- No blank white screen.
- Bottom navigation bar is visible.

---

### TC-003 — Warm Launch (App Restored from Background)
**Priority:** High
**Steps:**
1. Open the app and wait for page to load.
2. Press Home button (send to background).
3. Wait 30 seconds.
4. Re-open app from recent apps.

**Expected:**
- App resumes without crash.
- Previously loaded page state is retained (no full reload).
- No duplicate WebView instances.

---

### TC-004 — App Icon & Splash Screen
**Priority:** Medium
**Steps:**
1. Install app.
2. Observe launcher icon on home screen.
3. Launch app and observe splash.

**Expected:**
- App icon matches the tenant logo (`tenenet_logo.jpg`), not the default Flutter blue icon.
- No default Flutter loading behavior visible.

---

## 2. WebView Loading & Rendering

### TC-005 — Successful Page Load
**Priority:** Critical
**Steps:**
1. Launch app with internet connected.
2. Observe loading sequence.

**Expected:**
- `LinearProgressIndicator` appears at top during loading.
- Progress bar increments smoothly from 0% to 100%.
- Progress bar disappears after page finishes loading.
- Web page is fully rendered and interactive.
- URL loaded is exactly `https://urbaneasyflats.com/?type=tenant`.

---

### TC-006 — Page Scroll
**Priority:** High
**Steps:**
1. Load the tenant portal.
2. Scroll down on the page.
3. Scroll back up.

**Expected:**
- Smooth scrolling without jank.
- No rubber-band/overscroll bounce (JS injection disables this).
- Scrolled position maintained while navigating within page.

---

### TC-007 — Page Zoom
**Priority:** Medium
**Steps:**
1. Load the tenant portal.
2. Pinch-to-zoom in.
3. Pinch-to-zoom out.
4. Double-tap on page.

**Expected:**
- Pinch zoom works if web page allows it.
- OR zoom is disabled and page renders at correct mobile scale.
- No crash on zoom gesture.

---

### TC-008 — Links Within the Web App
**Priority:** High
**Steps:**
1. Load the tenant portal.
2. Log in to the tenant account.
3. Tap on internal navigation links (e.g., "Bills", "Support Tickets").

**Expected:**
- Internal links navigate within the same WebView (no external browser opens).
- URL changes to the linked page.
- Back button becomes enabled after navigation.
- Page loads and renders correctly.

---

### TC-009 — `target="_blank"` Links
**Priority:** High
**Steps:**
1. On the tenant portal, find or trigger a link that normally opens in a new tab.
2. Tap the link.

**Expected:**
- Link does NOT open in external browser.
- Link opens within the same WebView tab (JS injection patches `target="_blank"`).

---

### TC-010 — Hardware Acceleration
**Priority:** Medium
**Steps:**
1. Load pages with images, charts, or animations.
2. Observe rendering smoothness.

**Expected:**
- No visible rendering lag.
- Hardware acceleration is active (set in `AndroidManifest.xml`).

---

## 3. Navigation Controls

### TC-011 — Bottom Navigation Bar Visible
**Priority:** High
**Steps:**
1. Launch app and load the tenant portal.

**Expected:**
- Bottom navigation bar is visible (Android only).
- 4 buttons visible: Back arrow, Forward arrow, Refresh (circular arrow), Home (house icon).

---

### TC-012 — Back Button in Navigation Bar
**Priority:** High
**Steps:**
1. Load tenant portal and navigate to an inner page (e.g., tap "My Bills").
2. Tap the Back arrow in the bottom navigation bar.

**Expected:**
- Back arrow is ENABLED after navigating to inner page.
- Tapping back navigates to the previous page.
- Page history is maintained correctly.

---

### TC-013 — Back Button Disabled on First Page
**Priority:** Medium
**Steps:**
1. Launch app (fresh load at home URL).
2. Observe Back button state.

**Expected:**
- Back arrow in bottom nav is DISABLED (greyed out) when no history exists.
- Tapping disabled back button does nothing.

---

### TC-014 — Forward Button
**Priority:** Medium
**Steps:**
1. Navigate to an inner page.
2. Tap Back arrow (returns to previous page).
3. Tap Forward arrow.

**Expected:**
- Forward arrow becomes ENABLED after going back.
- Tapping forward navigates forward in history.
- Forward arrow becomes DISABLED after reaching the latest page.

---

### TC-015 — Refresh Button
**Priority:** High
**Steps:**
1. Load the tenant portal.
2. Tap the Refresh button in bottom nav.

**Expected:**
- Page reloads from scratch.
- Progress indicator appears again during reload.
- Page renders correctly after reload.
- Login session is preserved (cookies not cleared).

---

### TC-016 — Home Button
**Priority:** High
**Steps:**
1. Navigate to an inner page (e.g., "Support Tickets").
2. Tap the Home (house) button in bottom nav.

**Expected:**
- WebView loads `https://urbaneasyflats.com/?type=tenant`.
- User returns to home/landing page of the tenant portal.
- Progress indicator shows during load.

---

## 4. Back Button Behaviour

### TC-017 — Device Back Button with History
**Priority:** Critical
**Steps:**
1. Load tenant portal.
2. Navigate 2-3 levels deep (e.g., Home → Bills → Bill Detail).
3. Press the device hardware/gesture Back button.

**Expected:**
- Goes back one page in web history (Bill Detail → Bills).
- Does NOT exit the app.
- Repeating takes user through full back stack.

---

### TC-018 — Device Back Button on First Page (Exit Prompt)
**Priority:** Critical
**Steps:**
1. Launch app and load home page.
2. Ensure no web navigation history.
3. Press device hardware/gesture Back button.

**Expected:**
- An exit confirmation dialog OR toast appears (e.g., "Press back again to exit").
- If user presses Back once more quickly, app exits.
- If user does NOT press Back again within 2 seconds, app does not exit.

---

### TC-019 — Swipe Back Gesture (Android 10+)
**Priority:** High
**Steps:**
1. Load tenant portal.
2. Swipe from left edge of screen (Android back gesture).
3. Repeat from an inner page.

**Expected:**
- Gesture navigates web history (same as TC-017).
- Gesture on first page triggers exit prompt (same as TC-018).

---

## 5. Download — Direct File Downloads

### TC-020 — Download PDF (Rental Bill)
**Priority:** Critical
**Steps:**
1. Log in as tenant.
2. Go to Billing section.
3. Tap "Download" or "Download Receipt" on a bill.

**Expected:**
- Download progress overlay appears in Flutter UI.
- File is saved to the device's Downloads folder.
- Success dialog appears: "File Downloaded Successfully" with filename.
- Dialog offers "Open" and "Close" options.
- Tapping "Open" opens the PDF in the device's PDF viewer.

---

### TC-021 — Download PDF (Rental Contract)
**Priority:** Critical
**Steps:**
1. Log in as tenant.
2. Go to Rental Contracts section.
3. Tap "Download Contract".

**Expected:**
- Same flow as TC-020.
- File saved as `.pdf` with correct filename.
- PDF opens in viewer successfully.

---

### TC-022 — Download Excel File
**Priority:** High
**Steps:**
1. On the tenant portal, trigger an Excel export (e.g., export billing data).
2. Confirm the download.

**Expected:**
- `.xlsx` or `.csv` file is downloaded to Downloads folder.
- Success dialog shown.
- Tapping "Open" opens the file in a spreadsheet app (if installed).

---

### TC-023 — Download Filename Extraction
**Priority:** Medium
**Steps:**
1. Download multiple files from the portal.
2. Check the saved filenames in Downloads folder.

**Expected:**
- Filename extracted from `Content-Disposition` header (e.g., `rental_bill_123.pdf`).
- OR filename extracted from URL path if no header.
- Files NOT saved with generic names like `download` or `file`.

---

### TC-024 — Download with Session Cookies
**Priority:** High
**Steps:**
1. Log in to tenant portal.
2. Trigger a download that requires authentication.

**Expected:**
- Download succeeds (not a 401/403 error).
- App reads cookies from WebView and includes them in the HTTP download request.
- File is correct (not an HTML error page saved as PDF).

---

### TC-025 — Download When Storage Full
**Priority:** Low
**Steps:**
1. Fill device storage to near-full.
2. Attempt to download a file.

**Expected:**
- App shows an error message instead of crashing.
- No silent failure (user is informed).

---

### TC-026 — Multiple Consecutive Downloads
**Priority:** Medium
**Steps:**
1. Download File A.
2. Immediately download File B while File A is completing.

**Expected:**
- Both files are eventually saved correctly.
- No collision in filenames.
- No crash or ANR.

---

## 6. Download — Blob / XHR / Fetch Downloads

### TC-027 — Blob URL Download (Browser-Generated PDF)
**Priority:** Critical
**Steps:**
1. Trigger a download that the web app generates client-side (blob PDF, e.g., jsPDF or html2canvas output).
2. The URL will be in format `blob:https://...`.

**Expected:**
- App intercepts blob via JS channel (`DownloadChannel`).
- Base64 data received and decoded.
- File saved to Downloads with correct filename.
- Success dialog shown.

---

### TC-028 — XHR-Based Download
**Priority:** High
**Steps:**
1. Trigger a download initiated via `XMLHttpRequest` in the web app.

**Expected:**
- App's XHR patch intercepts the response.
- File downloaded correctly (same as direct download).
- No blank file saved.

---

### TC-029 — Fetch API Download
**Priority:** High
**Steps:**
1. Trigger a download initiated via `fetch()` in the web app.

**Expected:**
- App's `fetch()` patch intercepts the response.
- File downloaded correctly.

---

### TC-030 — Blob Download Filename
**Priority:** Medium
**Steps:**
1. Trigger a blob download that includes a filename hint in the web app.

**Expected:**
- Saved filename matches what the web app intended (not a random UUID).
- Filename has proper extension (`.pdf`, `.xlsx`, etc.).

---

## 7. File Upload

### TC-031 — Single File Upload (Image)
**Priority:** Critical
**Steps:**
1. Log in as tenant.
2. Go to Support Tickets → Create Ticket.
3. Tap the file/image attachment field.

**Expected:**
- Android native file picker opens.
- User can browse and select a single image file.
- Selected file is attached to the web form.
- Form shows filename or thumbnail of selected file.

---

### TC-032 — Single File Upload (PDF/Document)
**Priority:** High
**Steps:**
1. Go to a KYC or document upload section.
2. Tap the file upload field.
3. Select a PDF from the device.

**Expected:**
- Android file picker opens showing all file types (or filtered by MIME type from web form).
- PDF selected and attached to form.
- Form submission succeeds with the document.

---

### TC-033 — Multiple File Upload
**Priority:** High
**Steps:**
1. Go to a form that allows multiple file attachments.
2. Tap the file picker (multiple mode).
3. Select 3 files.

**Expected:**
- Android file picker opens in multi-select mode.
- All 3 files are attached.
- Form shows all selected files.

---

### TC-034 — File Upload — Cancel (No File Selected)
**Priority:** Medium
**Steps:**
1. Tap a file upload field.
2. Android file picker opens.
3. Press Back/Cancel without selecting a file.

**Expected:**
- No crash.
- Web form returns to its previous state.
- No null pointer or empty file submission error.

---

### TC-035 — File Upload — Large File
**Priority:** Medium
**Steps:**
1. Tap a file upload field.
2. Select a large file (>10 MB).

**Expected:**
- File is selected and attached (or a file-size validation error shown).
- No ANR or memory crash.

---

## 8. Network Connectivity

### TC-036 — Internet Disconnected While Loading
**Priority:** Critical
**Steps:**
1. Start loading the tenant portal.
2. While the progress indicator is visible, turn off WiFi/data.

**Expected:**
- Loading stops.
- Error message displayed: "No internet connection" or similar.
- "Try Again" button visible.

---

### TC-037 — Internet Disconnected While Using App
**Priority:** Critical
**Steps:**
1. Load and use the tenant portal normally.
2. Turn off WiFi/mobile data.

**Expected:**
- An error message or overlay appears indicating lost connectivity.
- App does not crash.
- User prompted to reconnect.

---

### TC-038 — Internet Reconnected
**Priority:** Critical
**Steps:**
1. From TC-037 (disconnected state).
2. Turn WiFi/data back on.

**Expected:**
- App detects reconnection automatically.
- Page auto-reloads OR a "Reconnected" prompt appears.
- User can resume using the app without manual refresh.

---

### TC-039 — Weak / Intermittent Connection
**Priority:** High
**Steps:**
1. Set device to a very weak network (simulated in developer options: "2G" throttle).
2. Launch the app.

**Expected:**
- App loads eventually (within 25-second timeout).
- Progress indicator remains visible during slow load.
- OR error screen with "Try Again" shows if timeout exceeded.

---

### TC-040 — Airplane Mode (No Network)
**Priority:** Medium
**Steps:**
1. Enable Airplane Mode.
2. Launch the app.

**Expected:**
- Error screen shown immediately.
- No crash.
- "Try Again" button visible and functional.

---

### TC-041 — Switch From WiFi to Mobile Data
**Priority:** Medium
**Steps:**
1. Load tenant portal on WiFi.
2. Disable WiFi (switches to mobile data automatically).

**Expected:**
- Brief connectivity change handled gracefully.
- Page either remains loaded or refreshes without crash.
- No "No internet" error if mobile data is available.

---

## 9. Special URL Handling (External Apps)

### TC-042 — Phone Number Link (tel:)
**Priority:** High
**Steps:**
1. On the tenant portal, find a phone number link (e.g., "Call Support").
2. Tap the phone number.

**Expected:**
- Android Phone/Dialer app opens with the number pre-filled.
- WebView does NOT navigate to the `tel:` URL (no white page).
- Returning from dialer brings user back to the app.

---

### TC-043 — Email Link (mailto:)
**Priority:** High
**Steps:**
1. Tap a "Contact via Email" or email address link.

**Expected:**
- Default email client opens with the address pre-filled.
- WebView does NOT navigate to the `mailto:` URL.

---

### TC-044 — WhatsApp Link
**Priority:** High
**Steps:**
1. Tap a "Chat on WhatsApp" link.

**Expected:**
- WhatsApp opens (if installed) with the contact pre-populated.
- If WhatsApp is NOT installed, a chooser dialog or error is shown.
- App does not crash.

---

### TC-045 — SMS Link (sms:)
**Priority:** Medium
**Steps:**
1. Tap an SMS link on the portal.

**Expected:**
- Default SMS app opens.
- WebView does NOT show a blank page.

---

### TC-046 — App Store Link (market: / itms-apps:)
**Priority:** Low
**Steps:**
1. Tap a "Rate App" or "Download on Play Store" link.

**Expected:**
- Google Play Store app opens (Android) or App Store (iOS).
- User not redirected to a browser version.

---

### TC-047 — External HTTP Link
**Priority:** Medium
**Steps:**
1. Tap a link to an external website (e.g., `https://razorpay.com`).

**Expected:**
- Depending on app behavior: either opens in same WebView OR opens in external browser.
- No blank screen or unhandled navigation.

---

## 10. Page Load Timeout & Error States

### TC-048 — Page Load Timeout (25 seconds)
**Priority:** High
**Steps:**
1. Simulate very slow network (developer options: slow down network to near 0).
2. Launch the app.
3. Wait 25+ seconds.

**Expected:**
- After 25 seconds, the timeout triggers.
- Loading indicator disappears.
- Error screen appears with message (e.g., "Page took too long to load").
- "Try Again" button is visible and functional.

---

### TC-049 — "Try Again" Button After Error
**Priority:** High
**Steps:**
1. Reach any error state (no internet, timeout, HTTP error).
2. Tap "Try Again".

**Expected:**
- WebView attempts to reload the home URL.
- Progress indicator appears.
- If internet is now available, page loads successfully.

---

### TC-050 — HTTP Error (404 / 500)
**Priority:** Medium
**Steps:**
1. Simulate or trigger a server-side error page.
2. (Hard to test directly — may require intercepting requests.)

**Expected:**
- Error screen OR the web app's own error page is displayed.
- App does not crash.
- Navigation controls remain functional.

---

### TC-051 — SSL Certificate Error
**Priority:** Medium
**Steps:**
1. If possible, try loading a URL with an invalid/expired certificate.

**Expected:**
- WebView shows the error (and blocks navigation per Android WebView default behavior).
- App does not crash.
- User is not silently loaded onto an insecure page.

---

### TC-052 — Mixed Content (HTTP resources on HTTPS page)
**Priority:** Low
**Steps:**
1. Load the tenant portal and observe console/network.

**Expected:**
- Page loads without visual issues.
- No mixed-content errors blocking images or resources.

---

## 11. JavaScript Injection & Web Interop

### TC-053 — Overscroll Disabled
**Priority:** Medium
**Steps:**
1. Load the tenant portal.
2. Try to scroll past the top or bottom of the page.

**Expected:**
- No rubber-band/bounce effect (disabled by JS injection: `overscroll-behavior: none`).
- Scroll stops at page boundary.

---

### TC-054 — Smooth Scroll Behaviour
**Priority:** Low
**Steps:**
1. Click an anchor link or "scroll to top" button on the page.

**Expected:**
- Scroll animates smoothly (JS injection sets `scroll-behavior: smooth`).

---

### TC-055 — `window.open()` Intercepted
**Priority:** High
**Steps:**
1. Trigger any action on the portal that normally uses `window.open()` (e.g., opening a file preview).

**Expected:**
- Opens in the same WebView instead of attempting to open a new window/tab.
- No blank window or crash.

---

### TC-056 — JavaScript Channel (`DownloadChannel`) Communication
**Priority:** High
**Steps:**
1. Trigger a blob download (see TC-027).
2. Observe that the download completes correctly.

**Expected:**
- JavaScript channel message from web page is received by Flutter.
- Message is parsed (base64 data + filename).
- File is saved and success dialog shown.
- No "channel not found" or silent failure.

---

### TC-057 — Form Submission Download Interception
**Priority:** Medium
**Steps:**
1. Trigger a download via a form POST (if the portal uses form submissions for downloads).

**Expected:**
- App intercepts the form-triggered download.
- File is saved correctly (not a navigation to a blank page).

---

## 12. App Lifecycle (Background / Foreground)

### TC-058 — Background During Download
**Priority:** High
**Steps:**
1. Start a file download.
2. Immediately press Home to background the app.
3. Return to the app.

**Expected:**
- Download either completes in background OR is paused cleanly.
- No crash on return.
- Success/failure dialog shown correctly after return.

---

### TC-059 — Screen Rotation During Load
**Priority:** Medium
**Steps:**
1. Start loading a page.
2. Rotate the device from portrait to landscape.

**Expected:**
- App handles rotation gracefully (no crash).
- WebView continues loading or reloads without going to error state.
- Bottom navigation bar remains visible.

---

### TC-060 — Screen Rotation While Using App
**Priority:** Medium
**Steps:**
1. Load the tenant portal fully.
2. Rotate device.

**Expected:**
- Page reloads in new orientation OR content reflows naturally.
- Login session preserved.
- No duplicate WebView instances.

---

### TC-061 — App Minimized and Resumed (Login Session)
**Priority:** High
**Steps:**
1. Log in to the tenant portal.
2. Minimize the app.
3. Wait 10 minutes.
4. Re-open the app.

**Expected:**
- User remains logged in (cookies preserved).
- Previously viewed page is still showing.
- No forced logout or re-authentication required.

---

### TC-062 — Low Memory — App Killed and Relaunched
**Priority:** Medium
**Steps:**
1. Log in to the portal.
2. Open many other apps to trigger low memory.
3. Wait until this app is killed by OS.
4. Reopen the app.

**Expected:**
- App cold-launches correctly.
- Returns to home URL (no crash trying to restore dead state).

---

## 13. Performance & UI/UX

### TC-063 — First Contentful Paint Speed
**Priority:** Medium
**Steps:**
1. Fresh cold launch with good WiFi.
2. Measure time until the tenant portal's content is first visible.

**Expected:**
- Content visible within 5 seconds on good WiFi (50+ Mbps).
- Content visible within 15 seconds on 4G.

---

### TC-064 — Memory Usage Over Time
**Priority:** Low
**Steps:**
1. Use the app continuously for 30 minutes, navigating through many pages.
2. Monitor memory usage via Android Studio / device info.

**Expected:**
- Memory usage does not grow unboundedly (no memory leak).
- App does not crash due to OOM (Out Of Memory).

---

### TC-065 — No White Flash on Load
**Priority:** Low
**Steps:**
1. Launch the app.
2. Observe the transition from splash to WebView.

**Expected:**
- Smooth fade-in transition (app uses opacity animations).
- No jarring white flash before content appears.

---

### TC-066 — Download Overlay UX
**Priority:** Medium
**Steps:**
1. Trigger a file download.

**Expected:**
- A visible overlay or spinner indicates "Download in progress".
- UI remains responsive (user can still see the web page behind the overlay).
- Overlay disappears after download completes.
- Success dialog clearly shows filename and "Open" / "Close" options.

---

### TC-067 — Bottom Navigation Bar — No Overlap with Web Content
**Priority:** High
**Steps:**
1. Load the tenant portal.
2. Scroll to the bottom of any page.

**Expected:**
- Bottom navigation bar does not overlap web page content.
- Web page footer / buttons are accessible above the nav bar.
- `SafeArea` + proper padding applied.

---

### TC-068 — Status Bar Appearance
**Priority:** Low
**Steps:**
1. Observe the status bar while using the app.

**Expected:**
- Status bar is visible with correct icons (time, signal, battery).
- App does not hide the status bar.
- Status bar text color is readable against the app's header/background.

---

### TC-069 — App Label on Recents
**Priority:** Low
**Steps:**
1. Open the app.
2. Press the Recents/Overview button.

**Expected:**
- App card shows label "UrbanEasyFlats Tenant".
- App card shows a screenshot of the current state.
- Tapping the card resumes correctly (see TC-003).

---

### TC-070 — APK Install Size
**Priority:** Low
**Steps:**
1. Check the size of the debug or release APK.

**Expected:**
- APK size is reasonable for a WebView app (typically < 30 MB release build).
- Assets (logo image) are appropriately compressed.

---

## Summary Matrix

| TC # | Feature Area | Priority | Automated? |
|------|-------------|----------|------------|
| 001–004 | App Launch | Critical/High | Partial |
| 005–010 | WebView Loading | Critical/High | Partial |
| 011–016 | Navigation Controls | Critical/High | Manual |
| 017–019 | Back Button | Critical/High | Manual |
| 020–026 | Direct Downloads | Critical/High | Manual |
| 027–030 | Blob/XHR Downloads | Critical/High | Manual |
| 031–035 | File Upload | Critical/Medium | Manual |
| 036–041 | Connectivity | Critical/Medium | Manual |
| 042–047 | Special URLs | High/Medium | Manual |
| 048–052 | Errors/Timeout | High/Medium | Partial |
| 053–057 | JS Injection | High/Medium | Manual |
| 058–062 | App Lifecycle | High/Medium | Manual |
| 063–070 | Performance/UX | Medium/Low | Manual |

**Total Test Cases: 70**

---

## Regression Test Priority (Run Before Every Release)

Run these 15 critical tests before every build release:

| # | Test | Reason |
|---|------|--------|
| TC-001 | Cold Launch | Core functionality |
| TC-002 | Launch — No Internet | Critical UX |
| TC-005 | Page Load | Core functionality |
| TC-008 | Internal Links | Core navigation |
| TC-015 | Refresh | Core navigation |
| TC-017 | Back with History | Core navigation |
| TC-018 | Back Exit Prompt | Core UX |
| TC-020 | Download PDF (Bill) | Key tenant feature |
| TC-021 | Download Contract | Key tenant feature |
| TC-027 | Blob Download | Key tenant feature |
| TC-031 | File Upload | Key tenant feature |
| TC-036 | Disconnect Mid-Load | Stability |
| TC-038 | Reconnect Auto-Reload | Stability |
| TC-042 | Phone Link (tel:) | External app interop |
| TC-061 | Session After Minimize | Auth/UX |
