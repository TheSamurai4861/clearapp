# Data Repositories

This layer implements the abstract contracts defined in the Domain layer (`lib/domain/repositories/`).

## Contents
* Concrete repository classes (e.g., `DuplicateRepositoryImpl`, `SettingsRepositoryImpl`).
* These classes orchestrate Data Services and local databases/file systems to satisfy domain contracts.

## Guidelines
* Coordinate between different local services (e.g., `FileService` for physical file scanning/deletion, `PreferencesService` for saving settings).
* Handle service-level exceptions and map them to domain-level `Failure` objects if a failure-based design is used.
