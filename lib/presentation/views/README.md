# Presentation Views

Views represent complete pages or screens of the application.

## Contents
* `home_view.dart`: The primary application dashboard.
* `scan_results_view.dart`: View listing found duplicates, sizes, categories, and cleanup actions.
* `settings_view.dart`: Settings page for scanner preferences, excluded folders, and filters.

## Guidelines
* Use views to combine widgets and lay out the screen.
* Avoid direct heavy business logic or low-level rendering inside views.
* Ensure layout responsiveness for both Android (mobile screens) and Windows (resizable desktop windows).
