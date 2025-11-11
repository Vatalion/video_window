# Manual Accessibility Testing - Story 5-2

## Overview

This document outlines manual QA steps for verifying accessibility compliance in Story 5-2: Accessible Playback & Transcripts. These tests should be performed using VoiceOver (iOS/macOS) and TalkBack (Android) screen readers.

**Last Updated:** 2025-11-11  
**Story:** 5-2-accessible-playback-and-transcripts  
**AC Coverage:** AC3, AC8

---

## Prerequisites

### iOS/macOS (VoiceOver)
- Device: iPhone/iPad or Mac
- iOS version: iOS 15+ or macOS 12+
- Enable VoiceOver: Settings → Accessibility → VoiceOver → On
- Shortcut: Triple-click Home button (iOS) or Cmd+F5 (macOS)

### Android (TalkBack)
- Device: Android phone/tablet
- Android version: Android 8.0+
- Enable TalkBack: Settings → Accessibility → TalkBack → On
- Shortcut: Hold Volume Up + Volume Down for 3 seconds

---

## Test Cases

### TC-1: Screen Reader Announcements for Playback State Changes

**Objective:** Verify screen reader announces playback state transitions

**Steps:**
1. Navigate to a story detail page with video
2. Locate the video player using VoiceOver/TalkBack navigation
3. Activate the play button
4. **Expected:** Screen reader announces "Video playing"
5. Activate the pause button
6. **Expected:** Screen reader announces "Video paused"
7. Wait for video to buffer (if applicable)
8. **Expected:** Screen reader announces "Video buffering"

**Acceptance Criteria:** AC3

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### TC-2: Section Navigation Announcements

**Objective:** Verify screen reader announces section navigation

**Steps:**
1. Navigate to story detail page
2. Locate section navigation tabs (Overview, Process, Materials, etc.)
3. Navigate between sections using swipe gestures (VoiceOver) or swipe right (TalkBack)
4. **Expected:** Screen reader announces "Navigated to [section name] section" for each section change

**Acceptance Criteria:** AC3

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### TC-3: Transcript Selection Announcements

**Objective:** Verify screen reader announces transcript cue selection

**Steps:**
1. Open transcript panel
2. Navigate through transcript cues using keyboard or swipe gestures
3. Select a transcript cue
4. **Expected:** Screen reader announces "Transcript cue: [timestamp] to [timestamp]"
5. Double-tap to seek to that position
6. **Expected:** Screen reader announces seek action and video position updates

**Acceptance Criteria:** AC3

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### TC-4: Keyboard Navigation - Tab Order

**Objective:** Verify logical focus order for keyboard navigation

**Steps:**
1. Navigate to story detail page
2. Use Tab key to navigate through interactive elements
3. **Expected Focus Order:**
   - Video Player
   - Play/Pause Button
   - Caption Toggle Button
   - Transcript Panel Toggle
   - Search Box (in transcript panel)
   - Transcript List Items
4. Use Shift+Tab to navigate backwards
5. **Expected:** Focus moves in reverse order

**Acceptance Criteria:** AC2, AC4

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### TC-5: Keyboard Shortcuts

**Objective:** Verify keyboard shortcuts work without conflicts

**Steps:**
1. Focus on video player
2. Press Space key
3. **Expected:** Video toggles play/pause
4. Press Arrow Left key
5. **Expected:** Video seeks backward 10 seconds
6. Press Arrow Right key
7. **Expected:** Video seeks forward 10 seconds
8. Press Arrow Up key
9. **Expected:** Volume increases
10. Press Arrow Down key
11. **Expected:** Volume decreases
12. Press C key
13. **Expected:** Captions toggle on/off
14. Press F key
15. **Expected:** Fullscreen toggles

**Acceptance Criteria:** AC4

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### TC-6: High Contrast Mode Detection

**Objective:** Verify high contrast mode is auto-detected and applied

**Steps:**
1. Enable high contrast mode in system settings:
   - **iOS:** Settings → Accessibility → Display & Text Size → Increase Contrast → On
   - **Android:** Settings → Accessibility → Display → High Contrast Text → On
   - **macOS:** System Preferences → Accessibility → Display → Increase Contrast
2. Navigate to story detail page
3. **Expected:** Video player controls use high contrast colors (black/white)
4. **Expected:** Caption text uses high contrast styling
5. **Expected:** Transcript panel uses high contrast theme
6. Disable high contrast mode
7. **Expected:** Theme reverts to normal without requiring app restart

**Acceptance Criteria:** AC5

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### TC-7: Reduced Motion Preference

**Objective:** Verify reduced motion preference disables animations

**Steps:**
1. Enable reduced motion in system settings:
   - **iOS:** Settings → Accessibility → Motion → Reduce Motion → On
   - **Android:** Settings → Accessibility → Remove Animations → On
   - **macOS:** System Preferences → Accessibility → Display → Reduce Motion
2. Navigate to story detail page
3. **Expected:** No auto-play animations
4. **Expected:** Transitions are instant or minimal
5. **Expected:** Video controls appear without animation
6. Disable reduced motion
7. **Expected:** Animations resume without requiring app restart

**Acceptance Criteria:** AC5

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### TC-8: Caption Language Switching

**Objective:** Verify caption language tracks can be switched

**Steps:**
1. Navigate to story detail page with captions enabled
2. Open caption settings menu
3. Select English caption track
4. **Expected:** English captions display
5. Switch to Spanish caption track
6. **Expected:** Spanish captions display
7. Switch to French caption track
8. **Expected:** French captions display

**Acceptance Criteria:** AC1

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### TC-9: Transcript Search Functionality

**Objective:** Verify transcript search works with screen reader

**Steps:**
1. Open transcript panel
2. Navigate to search box using keyboard or swipe
3. Enter search term using on-screen keyboard
4. **Expected:** Transcript list filters to show matching cues
5. **Expected:** Screen reader announces number of results
6. Navigate through filtered results
7. **Expected:** Matching text is highlighted (visually)
8. Select a matching cue
9. **Expected:** Video seeks to that position

**Acceptance Criteria:** AC2

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### TC-10: WCAG 2.1 AA Contrast Compliance

**Objective:** Verify caption text meets WCAG 2.1 AA contrast requirements

**Steps:**
1. Enable captions on video
2. Verify caption text contrast:
   - **Normal mode:** Dark background (black with 80% opacity) with white text
   - **High contrast mode:** White background with black text
3. Use contrast checker tool to verify:
   - **Expected:** Contrast ratio ≥ 4.5:1 for normal text
   - **Expected:** Contrast ratio ≥ 3:1 for large text (18pt+)
4. Test with various video backgrounds (light, dark, colorful)

**Acceptance Criteria:** AC1

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

## Test Execution Checklist

- [ ] TC-1: Playback state announcements
- [ ] TC-2: Section navigation announcements
- [ ] TC-3: Transcript selection announcements
- [ ] TC-4: Keyboard navigation tab order
- [ ] TC-5: Keyboard shortcuts
- [ ] TC-6: High contrast mode detection
- [ ] TC-7: Reduced motion preference
- [ ] TC-8: Caption language switching
- [ ] TC-9: Transcript search functionality
- [ ] TC-10: WCAG 2.1 AA contrast compliance

## Issues Found

| Test Case | Severity | Description | Status |
|-----------|----------|-------------|--------|
|           |          |             |        |

## Sign-off

**Tester Name:** _________________  
**Date:** _________________  
**Overall Result:** ☐ Pass ☐ Fail  
**Notes:**

