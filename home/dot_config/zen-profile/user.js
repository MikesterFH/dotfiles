// Zen Browser prefs, copied into every default Zen profile on each
// `chezmoi apply` (run_after_install-zen-profile), see
// docs/adr/0016-zen-browser-profile-files.md. Zen reads user.js at startup
// and lets it override prefs.js, so a pref set here wins over a change in
// about:config after the next restart. Remove a line here to give the pref
// back to about:config; prefs it already set stay in prefs.js until reset.

// Load chrome/userChrome.css (and userContent.css) from the profile
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
