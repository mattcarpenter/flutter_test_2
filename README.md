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
[ ] Navigation Epic
  [X] Try navigating to new route
  [X] Document the relevant bits of my component tree for Cupertino
  [X] Leading padding
  [X] Make new widget tree docs
  [X] Regression test iPhone
  [X] Android Adaptive Widget Updates
  [X] Might need to create a page "wrapper" or some utility to manage android/ios diffs and manage the padding logic
  [X] Repurpose pages as tab navigators
  [X] Go router: simplify rest of pages; simplify directory structures
  [X] Go router: fix weird animations on tab changes
  [X] Go router: replace old app with this new one
  [X] Regression test android phone
  [X] Regression test android tablet
  [X] Routes that dont have a bottom nav bar
  [ ] Figure out menu button for pages outside of main scaffold
  [ ] Figure out why we get a back button instead of the previous title
  [ ] Fix weird padding in nav bar on sub routes
  [ ] Test deep-linking
  [ ] Hack android SliverAppBar to allow padding
  [ ] Go router: Since we have a shell; maybe Windows and Macos fit into this pattern? Investigate
[ ] Think about MacOS
[ ] Think about Windows
[ ] Android dark mode colors
[ ] Spec for tree nav (look at Notion?)
[ ] Finish impl of tree nav (minus nav)

### Thinking
* macos app.dart will be very similar to mobile app.dart. same for windows.
  * Might need to abstract just a little bit of common stuff out. maybe implement mac first and see the diffs
* realistically a lot of the stuff in mobile might become not-mobile-specific

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
