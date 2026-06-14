# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Deutsch Up** — a Flutter app for learning German vocabulary "like scrolling short videos": the user swipes vertically through word cards, hears each word + example sentence via TTS, and a dwell-time-based spaced-repetition engine schedules reviews. The UI and most code comments are in Chinese (词 = word, 刷词 = "swipe/grind words", 复习 = review). Words carry a Chinese gloss; the learner's first language is assumed to be Chinese.

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run on a connected device/emulator
flutter run -d macos            # run on desktop (uses sqflite_common_ffi)
flutter analyze                 # static analysis / lint (flutter_lints rules)
flutter test                    # run all tests
flutter test test/widget_test.dart --plain-name "name"   # run a single test by name
```

There is no separate build/lint config beyond `analysis_options.yaml` (stock `flutter_lints`). Lint and analyze are the same command (`flutter analyze`).

## Architecture

State flows through a single `ChangeNotifierProvider<LearningProvider>` created in `main.dart`. `LearningProvider` (`lib/providers/learning_provider.dart`) is the one source of truth for the active word list, per-word progress, the current card index, and the per-card countdown timer; screens only read/watch it. The layering is `screens` (UI) → `providers` (orchestration) → `services` (DB / TTS / scheduling) → `models`.

**Startup**: `SplashScreen` in `main.dart` calls `provider.initialize()` (TTS setup + first word load) before showing `HomeScreen`, with an error/retry state if init throws.

### The core mechanic: dwell-time spaced repetition

This is the non-obvious heart of the app and lives in `lib/services/spaced_repetition_service.dart`. Unlike classic SRS, the user **never self-rates**. Instead each card has a 20-second timer (`cardTimeoutSeconds`); the provider measures how long the card stayed visible (dwell time) and infers familiarity from it: a fast swipe (<4s) ⇒ `mastered` ⇒ long next interval; lingering or timing out (16s+) ⇒ `unknown` ⇒ the word reappears in ~1 minute. `review()` maps dwell → `Familiarity` → `intervalDays` (capped at 30) and updates an SM-2-style `easinessFactor`. `Familiarity` (in `lib/models/user_progress.dart`) also defines the card's color gradient (red→green).

The timing loop is in `LearningProvider`: `_startCardTimer` ticks every 100ms updating `timerProgress`/`remainingSeconds`; on timeout `_onCardTimeout` settles the card and fires the `onAutoFlip` callback. `_finishCurrentCard` is the single settle point — it computes dwell, calls `SpacedRepetitionService.review`, and persists via `DatabaseService.saveProgress`. It runs on every card transition: manual swipe, auto-flip, screen hide, and dispose.

### Screen ↔ provider auto-flip contract

`LearnScreen` (`lib/screens/learn_screen.dart`) owns a vertical `PageView`. The provider can't move the page itself, so the screen registers `provider.onAutoFlip` to animate to the next page on timeout, and nulls it in `dispose()`. `onPageChanged` must call `onManualSwipe()` then `onCardVisible(index)` so the previous card is settled before the new one starts. When editing card navigation, preserve this settle-then-advance ordering or progress will be miscounted.

### Persistence

`DatabaseService` (`lib/services/database_service.dart`) is a singleton over SQLite. It auto-selects the FFI backend (`sqflite_common_ffi`) on desktop (Windows/Linux/macOS) and stock `sqflite` on mobile. Two tables: `words` (seeded content) and `user_progress`. `getDueWords` is the key query — it LEFT JOINs progress and returns words whose `nextReviewAt` is null or past, ordered by due time.

**Word content is seeded from `assets/data/all_words.json` only** (via `_loadWordsFromAssets`). The per-level files (`a1_words.json`…`c2_words.json`) exist but are NOT loaded by the app; `all_words.json` is the source of truth (currently ~316 words, mostly A1). To change the word set, edit `all_words.json` and re-seed.

**Schema migrations**: bump `version` in `_initDatabase` and add an `onUpgrade` branch. Word-data changes are applied by `DELETE FROM words` + `_seedWords` inside `onUpgrade` (see the v3/v4 branches) — there's no incremental word migration. The DB file (`deutsch_up.db`) is NOT reset by hot reload, so adding words during development requires bumping the version to trigger re-seed.

### TTS

`TTSService` wraps `flutter_tts` fixed to `de-DE` at 0.45 speech rate. `speakWordAndSentence` reads "word. sentence" in one utterance. The provider speaks the current card automatically on load and on each card-visible event.

## Conventions

- Models are immutable with `toMap`/`fromMap`/`copyWith`; SQLite stores enums by their `.label` (`CEFRLevel`) and `tags` as a comma-joined string.
- `Word.id` follows `{level}_{seq}`, e.g. `a1_001`.
- Comments and user-facing strings are Chinese; keep that consistent when adding code.
