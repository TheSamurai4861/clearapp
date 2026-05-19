# Core Utilities Layer

This directory contains pure helpers, utilities, constants, and extensions used across the application.

## Contents
* **Extensions**: Dart extension methods (e.g., `BuildContext` helpers, String helpers).
* **Formatters**: String/Number/Size formatters (very useful for file size representation in duplicates scanner, e.g. converting bytes to KB/MB/GB).
* **Constants**: Global non-UI constants (e.g., file extensions, scanning configurations).
* **Helpers**: General-purpose helper functions.

## Guidelines
* Code here must have **no dependency** on external feature-specific logic.
* Keep utilities pure and highly testable.
