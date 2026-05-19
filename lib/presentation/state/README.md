# Presentation State Management

This layer manages the application state and business logic for the UI. It translates user actions from views into Domain Use Cases and exposes state streams or properties for widgets to rebuild.

## Contents
* State managers like BLoC/Cubit, Riverpod Providers, or ChangeNotifiers.
* State classes (e.g., `ScanIdle`, `ScanLoading`, `ScanCompleted`, `DeletionProgress`).
* Events or actions triggered by the UI.

## Guidelines
* State managers should call **Use Cases**, not concrete repositories directly, to respect Clean Architecture principles.
* Keep business logic entirely out of the UI widgets. Widgets should only listen to state changes and trigger methods on the state manager.
