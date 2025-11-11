# Battery Optimization Toggles - Release Notes

**Story:** 4-4-feed-performance-optimization  
**Release:** TBD  
**Date:** 2025-11-10

## Overview

This release introduces battery optimization features for the video feed, including automatic battery saver mode detection and wakelock management to reduce battery drain.

## New Features

### Battery Saver Mode Detection (AC5)

The feed now automatically detects when the device enters battery saver mode and adjusts behavior accordingly:

- **Auto-play disabled:** Videos pause automatically when battery saver mode is active
- **Preloading disabled:** Video preloading stops to conserve battery
- **UI indicator:** Visual indicator appears when battery saver mode is active (if feature flag enabled)

### Wakelock Management (AC4)

Improved wakelock management ensures the screen stays awake only when needed:

- **Automatic release:** Wakelock is released within 3 seconds of leaving the feed
- **Battery optimization:** Reduces unnecessary battery drain from screen wake

### Performance Monitoring (AC1, AC3, AC4)

New performance monitoring features help track feed performance:

- **Performance overlay:** Toggle via long-press on video feed item (requires feature flag)
- **Metrics displayed:**
  - FPS (frames per second)
  - Jank percentage
  - Memory delta
  - CPU utilization
  - Preload queue depth
  - Cache evictions

## Feature Flags

### `feed_performance_monitoring`

Controls visibility of performance debug overlay.

- **Default:** Disabled
- **Enable:** Set feature flag to `true` in app configuration
- **Usage:** Long-press on video feed item to toggle overlay

## Technical Details

### Battery Saver Detection

- Uses `battery_plus` package for battery state monitoring
- Detects low battery (< 20%) and discharging state
- Automatically pauses playback and disables preloading

### Wakelock Timing

- Wakelock acquired when video starts playing
- Wakelock released when video player is disposed
- Validation ensures release within 3 seconds

### Performance Metrics

- Frame timing via `SchedulerBinding.instance.addTimingsCallback`
- Memory monitoring via `MemoryMonitorService`
- CPU utilization estimation based on frame timing
- Metrics published to Datadog (when SDK integrated) and Firebase Performance (when SDK integrated)

## QA Checklist

Before release, verify:

- [ ] Battery saver mode detection works correctly
- [ ] Videos pause when battery saver activates
- [ ] Preloading stops when battery saver activates
- [ ] Wakelock releases within 3 seconds
- [ ] Performance overlay displays correctly (when feature flag enabled)
- [ ] All metrics are accurate
- [ ] No performance degradation

## Known Limitations

- Battery saver detection uses battery level as proxy (true battery saver detection requires platform channels)
- CPU monitoring is estimated (true CPU monitoring requires platform channels)
- Datadog and Firebase Performance SDKs not yet integrated (TODOs in code)

## Future Enhancements

- Platform-specific battery saver detection
- True CPU utilization monitoring
- Datadog SDK integration
- Firebase Performance SDK integration
- UI stump for battery saver override

