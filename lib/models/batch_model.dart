// Re-export BatchReport model for modules that expect models in `lib/models`.
// This keeps the existing `common.dart` as the single source of truth.

export '../screens/common.dart' show BatchReport, BatchStatus;
