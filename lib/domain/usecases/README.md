# Domain Use Cases

Use Cases encapsulate specific business rules and operations of the application. They coordinate the flow of data from repositories to achieve a specific user goal.

## Contents
* Use Case classes like:
  * `ScanDuplicatesUseCase`: Runs the duplication scanning algorithm.
  * `DeleteDuplicatesUseCase`: Deletes specific files and releases storage space.
  * `GetScannedFoldersUseCase`: Retrieves directories currently configured for cleanup.

## Guidelines
* Each Use Case should ideally do **only one thing** (Single Responsibility Principle).
* Typically, a Use Case exposes a single public method like `call()` or `execute()`.
* They must only depend on abstract Repositories and pure Entities, never concrete Data Sources or State Managers.
