# Reading Fonts and Topic Tab Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend reading font scaling to 300%, add an independent topic-list title scale, and make active topic tabs dispatch the configured single/double-tap navigation actions.

**Architecture:** Keep persisted reading preferences in `preferences_provider.dart` and reuse one set of scale constants from the settings definitions. Apply topic-title scaling only inside the shared `TopicCard` and `CompactTopicCard` title spans. Add a small topic-tab tap coordinator that mirrors the existing 300 ms navigation semantics without changing `adaptive_navigation.dart`; `TopicsPage` dispatches resulting actions through the existing home navigation action bus.

**Tech Stack:** Flutter, Dart, Riverpod, SharedPreferences, slang localization generation, Flutter widget/unit tests, Windows desktop release build.

## Global Constraints

- Both font scales use minimum `0.8`, maximum `3.0`, default/reset `1.0`, step `0.05`, and Slider `divisions: 44`.
- Persist the new title scale under the stable key `pref_topic_title_font_scale`.
- Clamp both persisted reads and setter writes to `0.8..3.0`; do not migrate stored data.
- Scale only topic title text and title emoji; preserve metadata, avatars, badges, status icon sizes, two-line normal titles, one-line compact titles, and ellipsis behavior.
- An inactive topic tab switches immediately and dispatches no action.
- An active topic tab follows `bottomSingleTapAction` and `bottomDoubleTapAction` with the existing 300 ms mutually exclusive single/double split.
- A rapid double tap on an initially inactive tab treats the first tap as switching and the second as the first active tap, not as a double tap.
- Tab changes, pinned-tab changes, and disposal cancel stale pending actions.
- Dispatch through `ref.dispatchNavAction(NavEntryIds.home, navAction)`.
- Do not change or refactor existing bottom/side navigation behavior and do not add third-party dependencies.

---

### Task 1: Reading font preferences, settings, and localization

**Files:**
- Modify: `lib/providers/preferences_provider.dart:80-532`
- Modify: `lib/settings/definitions/reading_defs.dart:14-45`
- Modify: `lib/l10n/modules/appearance/appearance_en.arb`
- Modify: `lib/l10n/modules/appearance/appearance_zh.arb`
- Modify: `lib/l10n/modules/appearance/appearance_zh_HK.arb`
- Modify: `lib/l10n/modules/appearance/appearance_zh_TW.arb`
- Regenerate: `lib/l10n/app_localizations.dart`
- Regenerate: `lib/l10n/s.dart`
- Modify: `test/providers/preferences_provider_test.dart`
- Modify: `test/settings/reading_defs_test.dart`

**Interfaces:**
- Produces: `kReadingFontScaleMin`, `kReadingFontScaleMax`, `kReadingFontScaleDefault`, `kReadingFontScaleDivisions`.
- Produces: `AppPreferences.topicTitleFontScale` and `Future<void> PreferencesNotifier.setTopicTitleFontScale(double scale)`.
- Produces: localized getter `appearance_topicTitleFontSize` and settings item id `topicTitleFontScale`.

- [ ] **Step 1: Write failing preference tests**

Append tests that prove defaults, persisted-read clamping, setter clamping, and persistence:

```dart
group('reading font scales', () {
  test('both font scales default to 100 percent', () async {
    final container = await _createContainer();
    addTearDown(container.dispose);

    final preferences = container.read(preferencesProvider);
    expect(preferences.contentFontScale, kReadingFontScaleDefault);
    expect(preferences.topicTitleFontScale, kReadingFontScaleDefault);
  });

  test('persisted font scales are clamped on initialization', () async {
    final container = await _createContainer(initialValues: {
      'pref_content_font_scale': 4.2,
      'pref_topic_title_font_scale': 0.2,
    });
    addTearDown(container.dispose);

    final preferences = container.read(preferencesProvider);
    expect(preferences.contentFontScale, kReadingFontScaleMax);
    expect(preferences.topicTitleFontScale, kReadingFontScaleMin);
  });

  test('font scale setters clamp and persist values', () async {
    final container = await _createContainer();
    addTearDown(container.dispose);
    final notifier = container.read(preferencesProvider.notifier);

    await notifier.setContentFontScale(9);
    await notifier.setTopicTitleFontScale(0.1);

    final preferences = container.read(preferencesProvider);
    final storage = container.read(sharedPreferencesProvider);
    expect(preferences.contentFontScale, kReadingFontScaleMax);
    expect(preferences.topicTitleFontScale, kReadingFontScaleMin);
    expect(storage.getDouble('pref_content_font_scale'), kReadingFontScaleMax);
    expect(
      storage.getDouble('pref_topic_title_font_scale'),
      kReadingFontScaleMin,
    );
  });
});
```

- [ ] **Step 2: Write failing settings-definition tests**

Add a test that casts both items to `DoubleSliderModel` and verifies order and exact slider metadata:

```dart
testWidgets('reading font sliders share the 80 to 300 percent range', (
  tester,
) async {
  final items = await _pumpAndCollectBasicItems(
    tester,
    size: const Size(390, 844),
    desktopOverride: false,
  );
  final ids = items.map((item) => item.id).toList();
  final contentIndex = ids.indexOf('contentFontScale');
  final topicIndex = ids.indexOf('topicTitleFontScale');

  expect(topicIndex, contentIndex + 1);
  for (final slider in <DoubleSliderModel>[
    items[contentIndex] as DoubleSliderModel,
    items[topicIndex] as DoubleSliderModel,
  ]) {
    expect(slider.min, kReadingFontScaleMin);
    expect(slider.max, kReadingFontScaleMax);
    expect(slider.divisions, kReadingFontScaleDivisions);
    expect(slider.labelBuilder(1.75), '175%');
    expect(slider.onReset, isNotNull);
  }
});
```

Import `preferences_provider.dart` in this test for the shared constants.

- [ ] **Step 3: Run the focused tests and verify RED**

Run:

```powershell
flutter test test/providers/preferences_provider_test.dart test/settings/reading_defs_test.dart
```

Expected: compilation/test failures because `topicTitleFontScale`, its setter/constants, and its settings item do not exist and the old content slider still ends at 1.4.

- [ ] **Step 4: Implement shared preference constants and storage**

Add top-level constants before `AppPreferences`:

```dart
const double kReadingFontScaleMin = 0.8;
const double kReadingFontScaleMax = 3.0;
const double kReadingFontScaleDefault = 1.0;
const int kReadingFontScaleDivisions = 44;

double _clampReadingFontScale(double value) =>
    value.clamp(kReadingFontScaleMin, kReadingFontScaleMax).toDouble();
```

Add `topicTitleFontScale` beside `contentFontScale` in fields, constructor, `copyWith` parameters, and returned `AppPreferences`. Add the key and clamp both initializer reads:

```dart
static const String _topicTitleFontScaleKey =
    'pref_topic_title_font_scale';

contentFontScale: _clampReadingFontScale(
  _prefs.getDouble(_contentFontScaleKey) ?? kReadingFontScaleDefault,
),
topicTitleFontScale: _clampReadingFontScale(
  _prefs.getDouble(_topicTitleFontScaleKey) ?? kReadingFontScaleDefault,
),
```

Use the same helper in both setters and persist the clamped `double`.

- [ ] **Step 5: Add localized copy and both slider definitions**

Add these ARB values directly after `appearance_contentFontSize`:

```json
// appearance_en.arb
"appearance_topicTitleFontSize": "Topic list title font size",
// appearance_zh.arb
"appearance_topicTitleFontSize": "帖子列表标题字体大小",
// appearance_zh_HK.arb
"appearance_topicTitleFontSize": "帖子列表標題字體大小",
// appearance_zh_TW.arb
"appearance_topicTitleFontSize": "帖子列表標題字型大小",
```

Update `contentFontScale` and insert `topicTitleFontScale` immediately after it, both using the shared constants, percentage label builder, and reset default.

- [ ] **Step 6: Generate localization code and verify GREEN**

Run:

```powershell
dart run tool/gen_l10n.dart
flutter test test/providers/preferences_provider_test.dart test/settings/reading_defs_test.dart
```

Expected: localization generation exits 0 and both focused test files pass.

- [ ] **Step 7: Format and commit Task 1**

```powershell
dart format lib/providers/preferences_provider.dart lib/settings/definitions/reading_defs.dart test/providers/preferences_provider_test.dart test/settings/reading_defs_test.dart
git add lib/providers/preferences_provider.dart lib/settings/definitions/reading_defs.dart lib/l10n test/providers/preferences_provider_test.dart test/settings/reading_defs_test.dart
git commit -m "feat: add topic title font preference"
```

---

### Task 2: Scale normal and compact topic titles only

**Files:**
- Modify: `lib/widgets/topic/topic_card.dart:1-604`
- Create: `test/widgets/topic/topic_card_test.dart`

**Interfaces:**
- Consumes: `AppPreferences.topicTitleFontScale` from Task 1.
- Produces: scaled title `TextStyle` passed to both the root `TextSpan` and `EmojiText.buildEmojiSpans`.

- [ ] **Step 1: Write failing widget tests**

Create a provider-scoped test harness with mocked SharedPreferences, `categoryMapProvider.overrideWithValue(const AsyncData({}))`, and a theme whose `titleMedium`, `labelMedium`, and `labelSmall` font sizes are known. Pump a topic titled `Scaled :smile:` with scale `2.0` and assert:

```dart
expect(normalTitle.text.style?.fontSize, 40);
expect(normalTitle.maxLines, 2);
expect(normalTitle.overflow, TextOverflow.ellipsis);
expect(normalEmojiImage.width, 48);
expect(find.byIcon(Symbols.lock_rounded), findsOneWidget);
expect(tester.widget<Icon>(find.byIcon(Symbols.lock_rounded)).size, 16);
expect(tester.widget<Text>(find.text('4')).style?.fontSize, 8);

expect(compactTitle.text.style?.fontSize, 24);
expect(compactTitle.maxLines, 1);
expect(compactTitle.overflow, TextOverflow.ellipsis);
expect(compactEmojiImage.width, closeTo(28.8, 0.001));
```

Use a helper that finds the `RichText` whose `text.toPlainText()` contains `Scaled`, and inspect the emoji `WidgetSpan`'s padded `Image`.

- [ ] **Step 2: Run the topic-card test and verify RED**

Run:

```powershell
flutter test test/widgets/topic/topic_card_test.dart
```

Expected: font-size and emoji-size expectations fail because both cards still use unscaled theme styles.

- [ ] **Step 3: Implement minimal title-only scaling**

Import `preferences_provider.dart`. In each card, watch only the title scale:

```dart
final topicTitleFontScale = ref.watch(
  preferencesProvider.select(
    (preferences) => preferences.topicTitleFontScale,
  ),
);
```

For the normal card, build one `titleStyle` from `titleMedium` with `fontSize: (base.fontSize ?? 16) * topicTitleFontScale` plus the existing weight, height, and color. For the compact card, do the same from `labelMedium` with fallback 12. Pass each computed style both to the root `TextSpan.style` and to `EmojiText.buildEmojiSpans`. Do not alter status icon constants, reply/category/time styles, max lines, or overflow.

- [ ] **Step 4: Verify GREEN and commit Task 2**

Run:

```powershell
dart format lib/widgets/topic/topic_card.dart test/widgets/topic/topic_card_test.dart
flutter test test/widgets/topic/topic_card_test.dart
git add lib/widgets/topic/topic_card.dart test/widgets/topic/topic_card_test.dart
git commit -m "feat: scale topic list titles"
```

Expected: topic-card tests pass with title/emoji scaling and unchanged metadata constraints.

---

### Task 3: Apply configured active-item actions to topic tabs

**Files:**
- Create: `lib/navigation/topic_tab_tap_coordinator.dart`
- Create: `test/navigation/topic_tab_tap_coordinator_test.dart`
- Modify: `lib/pages/topics_page.dart:127-242,633-637`

**Interfaces:**
- Consumes: `NavTapAction`, `NavAction`, and `NavTapActionX.toNavAction()`.
- Produces: `TopicTabTapCoordinator.handleTap(...)`, `syncActiveIndex(int index)`, `reset({required int activeIndex})`, and `dispose()`.
- Dispatch callback signature: `void Function(NavAction action)`.

- [ ] **Step 1: Write failing coordinator tests**

Create widget-timer tests covering indexes 0 and 1:

```dart
// inactive first tap: no action; second tap is first active click
coordinator.handleTap(index: 1, singleAction: NavTapAction.scrollToTop,
  doubleAction: NavTapAction.refresh, dispatch: actions.add);
coordinator.handleTap(index: 1, singleAction: NavTapAction.scrollToTop,
  doubleAction: NavTapAction.refresh, dispatch: actions.add);
coordinator.syncActiveIndex(1);
await tester.pump(const Duration(milliseconds: 300));
expect(actions, [NavAction.scrollToTop]);

// active double tap: pending single is cancelled
coordinator.handleTap(index: 0, singleAction: NavTapAction.scrollToTop,
  doubleAction: NavTapAction.refresh, dispatch: actions.add);
await tester.pump(const Duration(milliseconds: 100));
coordinator.handleTap(index: 0, singleAction: NavTapAction.scrollToTop,
  doubleAction: NavTapAction.refresh, dispatch: actions.add);
await tester.pump(const Duration(milliseconds: 300));
expect(actions, [NavAction.refresh]);
```

Also cover single-only immediate dispatch, double-only dispatch, both-none, switching to a different active index cancelling a pending single, `reset` for pinned-category changes, and `dispose` cancellation.

- [ ] **Step 2: Run the coordinator test and verify RED**

Run:

```powershell
flutter test test/navigation/topic_tab_tap_coordinator_test.dart
```

Expected: compilation fails because `TopicTabTapCoordinator` does not exist.

- [ ] **Step 3: Implement the 300 ms coordinator**

Implement a small class with logical active-index tracking. On an inactive tap it cancels pending state, updates the logical active index immediately, and returns without dispatch; this makes a second rapid tap the first active tap even while the TabController animation is still settling. On active taps, mirror the existing navigation behavior: immediate single when no double action exists, delayed single when a double action exists, double cancels pending single, double-only records the first tap, and none/none dispatches nothing. `syncActiveIndex` cancels only when an external/programmatic switch changes to a different logical index; settling the same just-clicked tab must not cancel its newly scheduled active single action.

- [ ] **Step 4: Integrate with TopicsPage**

Initialize the coordinator with index 0 in `initState`. Replace the direct scroll-to-top callback with:

```dart
onTabTap: (index) {
  final preferences = ref.read(preferencesProvider);
  _topicTabTapCoordinator.handleTap(
    index: index,
    singleAction: preferences.bottomSingleTapAction,
    doubleAction: preferences.bottomDoubleTapAction,
    dispatch: (navAction) {
      ref.dispatchNavAction(NavEntryIds.home, navAction);
    },
  );
},
```

Call `syncActiveIndex(_tabController.index)` when `_handleTabChange` observes a real changed index. Call `reset(activeIndex: _currentTabIndex)` whenever pinned tabs rebuild, and `dispose()` before page disposal. Keep `adaptive_navigation.dart` untouched.

- [ ] **Step 5: Verify GREEN and commit Task 3**

Run:

```powershell
dart format lib/navigation/topic_tab_tap_coordinator.dart lib/pages/topics_page.dart test/navigation/topic_tab_tap_coordinator_test.dart
flutter test test/navigation/topic_tab_tap_coordinator_test.dart
git diff -- lib/widgets/layout/adaptive_navigation.dart
```

Expected: coordinator tests pass and the adaptive navigation diff is empty.

Then commit:

```powershell
git add lib/navigation/topic_tab_tap_coordinator.dart lib/pages/topics_page.dart test/navigation/topic_tab_tap_coordinator_test.dart
git commit -m "feat: apply nav actions to topic tabs"
```

---

### Task 4: Full verification and Windows artifact

**Files:**
- Verify all modified source/tests/localization files.
- Replace artifact: `D:\FLUXDO\test\fluxdo.exe`.

**Interfaces:**
- Consumes all prior task outputs.
- Produces a verified Windows release executable and a reviewable feature branch.

- [ ] **Step 1: Run generated-code and formatting checks**

```powershell
dart run tool/gen_l10n.dart --check
dart format --output=none --set-exit-if-changed lib/providers/preferences_provider.dart lib/settings/definitions/reading_defs.dart lib/widgets/topic/topic_card.dart lib/navigation/topic_tab_tap_coordinator.dart lib/pages/topics_page.dart test/providers/preferences_provider_test.dart test/settings/reading_defs_test.dart test/widgets/topic/topic_card_test.dart test/navigation/topic_tab_tap_coordinator_test.dart
```

Expected: both commands exit 0.

- [ ] **Step 2: Run focused and complete test suites**

```powershell
flutter test test/providers/preferences_provider_test.dart test/settings/reading_defs_test.dart test/widgets/topic/topic_card_test.dart test/navigation/topic_tab_tap_coordinator_test.dart
flutter test
```

Expected: all tests pass with zero failures.

- [ ] **Step 3: Run static analysis**

```powershell
flutter analyze
```

Expected: exit 0 with no analyzer errors.

- [ ] **Step 4: Build Windows release and install requested artifact**

```powershell
$env:PATH = "C:\Program Files\Git\mingw64\bin;$env:PATH"
$env:CL = "/utf-8"
flutter build windows --release
Copy-Item -LiteralPath "build\windows\x64\runner\Release\fluxdo.exe" -Destination "D:\FLUXDO\test\fluxdo.exe" -Force
Get-FileHash -Algorithm SHA256 "D:\FLUXDO\test\fluxdo.exe"
```

Expected: build exits 0, the destination exists, and SHA-256 is printed. Only if Flutter reports Windows plugin symlink privilege failure, temporarily enable Windows Developer Mode, retry the build, then restore the prior registry value.

- [ ] **Step 5: Inspect branch and final diff**

```powershell
git status --short --branch
git log --oneline upstream/main..HEAD
git diff --check upstream/main...HEAD
```

Expected: no uncommitted source changes, the design/implementation commits are listed, and `git diff --check` exits 0.

- [ ] **Step 6: Push and create the PR after verified completion**

Confirm the fork remote is the intended writable repository before pushing. Push `feat/reading-fonts-topic-tab-actions` and create a PR against `dashu33/fluxdo:main` with a concise summary, test evidence, and Windows build result. If authentication or fork remote ownership does not match, stop before mutating remotes and report the exact command the user must authorize or run.
