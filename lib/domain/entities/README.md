# Domain Entities

Entities represent the core business logic models of the application. They are pure Dart objects and contain no knowledge of databases, file systems, API clients, or state management frameworks.

## Contents
* Entities like `DuplicateFile` (representing a scanned duplicate file, its size, path, hash, original counterpart, etc.).
* Entities like `ScanFolder` (representing directories configured for scanning).
* Entities like `ScanReport` (representing summary statistics of a finished scan).

## Guidelines
* Entities must **extend `Equatable`** (or override `==` and `hashCode`) for correct comparison.
* They should **not** contain JSON serialization logic (`fromJson`/`toJson`). Serialization is a data layer concern and belongs in Data Models.
* They should remain highly stable and change only when business rules change.
