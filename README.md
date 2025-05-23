# flutter_test_2

A new Flutter project.

## TODO
### Goal: Sidebar UX finalized and implemented
- [X] Conditionally show close button in sidebar
- [X] Create color scheme library (sidebar bg color, active bg color, icon color) also support platform and light/dark
- [X] Adjust padding around active state
- [X] Get content colors sorted out in dark mode and light mode
- [X] Get rid of "Sidebar" text in cupertino sidebar and replace with placeholder
- [X] Replace cupertino sidebar content with sidebar content; make sure replacement animation still works
- [X] Add new menu component to phone
- [X] Fix active item styling in custom sidebar (update active state; ensure text is primary color when active)
- [X] Figure out active state for menu items
- [X] Navigation Epic
  - [X] Try navigating to new route
  - [X] Document the relevant bits of my component tree for Cupertino
  - [X] Leading padding
  - [X] Make new widget tree docs
  - [X] Regression test iPhone
  - [X] Android Adaptive Widget Updates
  - [X] Might need to create a page "wrapper" or some utility to manage android/ios diffs and manage the padding logic
  - [X] Repurpose pages as tab navigators
  - [X] Go router: simplify rest of pages; simplify directory structures
  - [X] Go router: fix weird animations on tab changes
  - [X] Go router: replace old app with this new one
  - [X] Regression test android phone
  - [X] Regression test android tablet
  - [X] Routes that dont have a bottom nav bar
  - [X] Figure out menu button for pages outside of main scaffold
  - [X] Ensure no extra nav bar on tablet when going to labs (did this regress because i added the shell?)
  - [X] Figure out why we get a back button instead of the previous title. reason: based on length
  - [X] Fix weird padding in nav bar on sub routes
  - [X] Test deep-linking
  - [X] Hack android SliverAppBar to allow padding for leading
- [X] Think about MacOS
- [X] Domain model
- [X] Implement Folders
  - [X] Supabase scaffolding
  - [X] Test boilerplate
  - [X] Sort out the role of riverpod vs repository (solve redundancy and simplify?)
  - [X] Sort out soft deletes (filtering in the query vs in code)
  - [X] Fix latency when adding folders
  - [X] Figure out sharing
  - [X] Parent/child?
  - [X] Figure out spacing in grid view - we specify how many cols
  - [X] Background color for folders from the theme
  - [X] Rounded corners for context menu box 
  - [X] Softer blur for context menu box - maybe we need to use the custom builder for this??
  - [X] Better folder icons
  - [X] Folder label font styles
  - [X] Fix padding for context menu box
  - [X] Why context menu background blur also blurs context menu on rightmost item?
  - [X] Unjank folders
  - [X] Test modal on android and make adjustments for adaptiveness
  - [X] Modal for tablet (add folder) see UIModalPresentationStyle.formSheet or showDialog with constrained dimensions
  - [X] Implement menu for adding folders (replace dummy textbox)
  - [X] Test folders on Android
  - [X] Folder deletion super broken (black screen)
  - [X] Folder context menu positioning weird on tablet
- [X] Fix breakpoints and show/hide sidebar animations
- [X] Android: Overflow issue on recipe cards
- [X] Android: Long press context menu on folder tiles incorrect positioning of menu
- [X] Implement Recipes
  - [X] Recipe capabilities
  - [X] Convert deletedAt to numeric timestamp
  - [X] New schemas (drift, powersync, postgres)
  - [X] Test it
  - [X] Clean up database directory
  - [X] DDLs including RLS
  - [X] Test RLS
  - [X] Attempt to implement folder sharing
  - [X] Add trigger that updates household id on share
  - [X] Regression test app
  - [X] Design test cases
  - [X] Implement Test Cases
  - [X] Create an ADR & document current RLS/Policy paradigms
  - [X] Refactor folder sharing (put in array on folders instead of join table) includes updating tests.
  - [X] Fix recipe sharing test
  - [X] Add more recipe sharing tests
  - [X] Ensure household members can see the other members not just themselves
  - [X] Fix recipe schema (userid req, rating not req)
  - [X] Reset Hosted supabase and PowerSync
  - [X] Regression test
  - [X] Delete folder in household owned by other does not work (RLS looks wrong)
  - [X] Re-collect requirements for ingredients and steps
  - [X] Come up with model for ingredients and steps
  - [X] Create classes and converters for ingredients and steps
  - [X] Create some repo methods for ingredients and steps
  - [X] Write tests for ingredients and steps related repo methods
  - [X] Initial dummy recipe adder UI
  - [X] Troubleshoot saving (black screen)
  - [X] Troubleshoot weird controlled input behavior
  - [X] Troubleshoot dragging behavior for ingredients and steps
  - [X] Ensure "lift" effect works and timing for long press is not too long
  - [X] Animate fade-out of drop shadow
  - [X] Don't refocus in the text input after drag completes
  - [X] Implement context menu showing
  - [X] Implement convert to section
  - [X] Split apart widgets
  - [X] Design for albums
  - [X] Implement albums
  - [X] Ensure recipes are created under folders (maybe need a product backlog to give us a folder selector if done outside of folder)
  - [X] Implement rough recipe list under folders
  - [X] Remove dummy recipes from recipe root page
  - [X] Recipe tile context menu & delete
  - [X] Implement rough recipe detail page skeleton and routing
  - [X] Add recipe details to details page
  - [X] Fix bug related to image upload attempts after update when token expired
  - [X] Implement Uncategorized "Folder"
  - [X] Implement folder deletion (recipes go to uncategorized)
  - [X] Implement sharing (backend only)
- [ ] Design Epic
  - [X] Build idea board figma and screenshots of current app
  - [X] Shortlist of designers w/ pros and cons
  - [X] Requirements for designer (included tags?)
  - [X] Message designer
  - [ ] Begin implementing new design
- [ ] Cook mode epic
  - [X] Cook mode specs
  - [X] design data model
  - [X] Implement models, ddls, repos, etc..
  - [X] Integration tests
  - [X] Get cook status (so we can use it in the UI like the button or dynamic island)
  - [X] Start cook button
  - [X] Implement rough cook mode
  - [X] Implement add recipe (depends on search epic)
- [ ] Search epic
  - [X] UX Research
  - [X] Consult GPT on FTS
  - [X] Consult GPT on implementation (both use cases - recipe search and add recipe for cook mode)
  - [X] Search implemented - no selection handlers yet
  - [X] Tap search result to navigate to recipe
- [ ] Bugs
  - [ ] Image bug (does not show in recipe detail page when anonymous)
  - [ ] user_household_shares has no RLS policies. RLS currently disabled
- [ ] Inventory epic
- [ ] Tags Epic
- [ ] Shopping List Epic
- [ ] Sharing epic
- [ ] Smart folders epic
- [ ] Discover epic
- [ ] Bake mode epic (bakers percentages)
- [ ] Sync Finalization Epic
  - [ ] Sync local-only data on auth
  - [ ] Implement method to sync uploaded images that were created before auth
- [ ] Mobile Platform Design Consistency Epic
  - [ ] Regression test Android
  - [ ] Light and Dark Mode
  - [ ] Inventory widgets that need to be adaptive
- [ ] Desktop Versions Epic
- [ ] L10n & Internationalization
  - [ ] Strings to l10n dictionary
  - [ ] Requirements for Internationalization (e.g., units)
- [ ] Settings epic
- [ ] Sidebar finalization epic
- [ ] Registration and sign-in epic
- [ ] Dynamic island for cook mode

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
