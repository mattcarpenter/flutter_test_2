# flutter_test_2

A new Flutter project.

## TODO
### Goal: Sidebar UX finalized and implemented
[X] Conditionally show close button in sidebar
[X] Create color scheme library (sidebar bg color, active bg color, icon color) also support platform and light/dark
[X] Adjust padding around active state
[X] Get content colors sorted out in dark mode and light mode
[X] Get rid of "Sidebar" text in cupertino sidebar and replace with placeholder
[X] Replace cupertino sidebar content with sidebar content; make sure replacement animation still works
[X] Add new menu component to phone
[X] Fix active item styling in custom sidebar (update active state; ensure text is primary color when active)
[X] Figure out active state for menu items
[ ] Experiment with CupertinoSliverNavigationBar
  [X] Try navigating to new route
  [X] Document the relevant bits of my component tree for Cupertino
  [X] Leading padding
  [X] Make new widget tree docs
  [X] Regression test iPhone
  [X] Android Adaptive Widget Updates
  [X] Might need to create a page "wrapper" or some utility to manage android/ios diffs and manage the padding logic
  [ ] Repurpose pages as tab navigators. Try out deep linking
  [ ] Hack SliverAppBar to allow padding
[ ] Think about MacOS
[ ] Think about Windows
[ ] Android dark mode colors
[ ] Spec for tree nav (look at Notion?)
[ ] Finish impl of tree nav (minus nav)

### Goal: Understand routing and pages
[ ] 

## Resources
https://schema.org/Recipe
https://bakewithrise.com/index.html

## Getting Started

This project is a starting point for a Flutter application that follows the
[simple app state management
tutorial](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple).

For help getting started with Flutter development, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Assets

The `assets` directory houses images, fonts, and any other files you want to
include with your application.

The `assets/images` directory contains [resolution-aware
images](https://flutter.dev/docs/development/ui/assets-and-images#resolution-aware).

## Localization

This project generates localized messages based on arb files found in
the `lib/src/localization` directory.

To support additional languages, please visit the tutorial on
[Internationalizing Flutter
apps](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)
