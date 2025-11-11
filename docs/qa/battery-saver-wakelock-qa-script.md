# Manual QA Script: Battery Saver & Wakelock Release

**Story:** 4-4-feed-performance-optimization  
**AC4, AC5:** Battery saver mode and wakelock release timing validation  
**Date:** 2025-11-10

## Prerequisites

- Test device with battery saver mode capability
- Stopwatch or timer
- Feed page accessible

## Test Cases

### Test Case 1: Battery Saver Mode Detection (AC5)

**Objective:** Verify battery saver mode disables auto-play and preloading

**Steps:**
1. Open feed page
2. Verify videos are auto-playing
3. Enable battery saver mode on device
4. Wait 2-3 seconds
5. Verify all videos pause automatically
6. Verify no new videos are preloaded
7. Verify UI stump appears to re-enable auto-play (if implemented)
8. Disable battery saver mode
9. Verify auto-play resumes

**Expected Results:**
- ✅ Videos pause when battery saver activates
- ✅ Preloading stops when battery saver activates
- ✅ UI stump appears (if implemented)
- ✅ Auto-play resumes when battery saver deactivates

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### Test Case 2: Wakelock Release Timing (AC4)

**Objective:** Verify wakelock is released within 3 seconds after feed exit

**Steps:**
1. Open feed page
2. Start playing a video
3. Note the time when video starts playing (wakelock acquired)
4. Navigate away from feed page (back button or home)
5. Start stopwatch immediately
6. Monitor device logs for wakelock release
7. Stop stopwatch when wakelock is released

**Expected Results:**
- ✅ Wakelock released within 3 seconds of leaving feed
- ✅ No wakelock warnings in logs

**Pass/Fail:** ☐ Pass ☐ Fail

**Actual Timing:** _____ seconds

**Notes:**

---

### Test Case 3: Battery Saver Override (AC5)

**Objective:** Verify user can override battery saver mode

**Steps:**
1. Enable battery saver mode
2. Open feed page
3. Verify videos are paused
4. Tap UI stump to re-enable auto-play (if implemented)
5. Verify videos resume playing
6. Verify preloading resumes

**Expected Results:**
- ✅ UI stump appears when battery saver is active
- ✅ Tapping stump re-enables auto-play
- ✅ Preloading resumes after override

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**

---

### Test Case 4: Performance Metrics During Battery Saver (AC4)

**Objective:** Verify CPU utilization remains low during battery saver mode

**Steps:**
1. Open feed page
2. Enable performance overlay (long-press)
3. Note CPU utilization
4. Enable battery saver mode
5. Wait 30 seconds
6. Note CPU utilization again

**Expected Results:**
- ✅ CPU utilization decreases when battery saver activates
- ✅ CPU utilization ≤ 45% average during 5-minute session

**Pass/Fail:** ☐ Pass ☐ Fail

**CPU Before:** _____%  
**CPU After:** _____%

**Notes:**

---

## Test Environment

**Device:** _________________  
**OS Version:** _________________  
**App Version:** _________________  
**Tester:** _________________  
**Date:** _________________

## Overall Result

☐ All tests passed  
☐ Some tests failed (see notes above)  
☐ Tests blocked (see notes above)

## Issues Found

1. 
2. 
3. 

