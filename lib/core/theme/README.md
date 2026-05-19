# Core Theme Layer

This directory contains the visual design system tokens, themes, and styles for ClearApp.

## Contents
* `app_theme.dart`: Design tokens defining the obsidian dark palette, premium styling, custom widget themes (buttons, cards, inputs), typography, spacing, and animations.

## Guidelines
* **Never hardcode visual values** (colors, padding, spacing, border radiuses, font sizes) in the presentation layer. Always use `AppColors`, `AppSpacing`, `AppBorderRadius`, or `Theme.of(context)` values.
* Custom theme extensions should be added here if needed for premium widgets.
