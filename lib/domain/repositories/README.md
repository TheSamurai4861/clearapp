# Domain Repositories

This layer defines the contracts (interfaces) for data operations required by the business rules (Use Cases).

## Contents
* Abstract classes/interfaces specifying the signatures for scanning, deleting duplicates, caching folders, etc.
* Examples:
  * `DuplicateRepository`: Contract for finding duplicates, deleting files, etc.
  * `SettingsRepository`: Contract for persisting scanner preferences.

## Guidelines
* This layer contains **only abstract classes**. No implementations allowed.
* Functions should return functional programming constructs like `Either<Failure, T>` (using the `fpdart` or `dartz` packages) to handle errors cleanly, or use standard Dart exceptions if preferred.
