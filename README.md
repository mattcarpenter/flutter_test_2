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
[X] Navigation Epic
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
  [X] Figure out menu button for pages outside of main scaffold
  [X] Ensure no extra nav bar on tablet when going to labs (did this regress because i added the shell?)
  [X] Figure out why we get a back button instead of the previous title. reason: based on length
  [X] Fix weird padding in nav bar on sub routes
  [X] Test deep-linking
  [X] Hack android SliverAppBar to allow padding for leading
[X] Think about MacOS
[X] Domain model
[X] Implement Folders
  [X] Supabase scaffolding
  [X] Test boilerplate
  [X] Sort out the role of riverpod vs repository (solve redundancy and simplify?)
  [X] Sort out soft deletes (filtering in the query vs in code)
  [X] Fix latency when adding folders
  [X] Figure out sharing
  [X] Parent/child?
  [X] Figure out spacing in grid view - we specify how many cols
  [X] Background color for folders from the theme
  [X] Rounded corners for context menu box 
  [X] Softer blur for context menu box - maybe we need to use the custom builder for this??
  [X] Better folder icons
  [X] Folder label font styles
  [X] Fix padding for context menu box
  [X] Why context menu background blur also blurs context menu on rightmost item?
  [X] Unjank folders
  [X] Test modal on android and make adjustments for adaptiveness
  [X] Modal for tablet (add folder) see UIModalPresentationStyle.formSheet or showDialog with constrained dimensions
  [X] Implement menu for adding folders (replace dummy textbox)
  [X] Test folders on Android
  [X] Folder deletion super broken (black screen)
  [X] Folder context menu positioning weird on tablet
[ ] Implement Recipes
  [X] Recipe capabilities
  [X] Convert deletedAt to numeric timestamp
  [X] New schemas (drift, powersync, postgres)
  [X] Test it
  [X] Clean up database directory
  [X] DDLs including RLS
  [X] Test RLS
  [X] Attempt to implement folder sharing
  [X] Add trigger that updates household id on share
  [X] Regression test app
  [X] Design test cases
  [X] Implement Test Cases
  [X] Create an ADR & document current RLS/Policy paradigms
  [ ] Refactor folder sharing (put in array on folders instead of join table)
      includes updating tests.
  [ ] Fix recipe sharing test
  [ ] Add more recipe sharing tests
  [ ] Fix recipe schema (userid req, rating not req)
  [X] Delete folder in household owned by other does not work (RLS looks wrong)
  [ ] Implement Recipe Ingredients and steps (can we use JSON?)
  [ ] Figure out integration tests
  [ ] Recipe schema & Riverpod
  [ ] Recipe integration test
  [ ] Dummy recipe adder UI
  [ ] Connect recipe list to Riverpod
  [ ] Deletion of folders - what happens to descendants
  [ ] Implement sharing
[ ] Check in on status of scroll bug https://github.com/flutter/flutter/issues/163297
[ ] Haptic feedback on context menu long-press
[X] Fix breakpoints and show/hide sidebar animations
[X] Android: Overflow issue on recipe cards
[X] Android: Long press context menu on folder tiles incorrect positioning of menu
[ ] Blue (or red?) back button
[ ] Revisit directory structure (mobile vs other platforms - are they necessary, can we consolidate or clean up)
[ ] Implement Basic Recipes
[ ] Think about Windows
[ ] L10n
[ ] Internationalization (default units settings)
[ ] Settings page
[ ] Transparent navigation sliver background??
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

## Unit Testing

Need to install some binaries for PowerSync: https://docs.powersync.com/client-sdk-references/flutter/unit-testing
