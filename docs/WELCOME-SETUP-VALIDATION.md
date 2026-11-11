# Persistent Welcome setup

Welcome now has five sequential pages: introduction, theme, wallpaper, bar and
completion. Existing theme, wallpaper service and bar controls persist choices.
The intro lasts 4 seconds and respects reduced motion. There is no setup timeout.
Escape goes back; close/tour cannot complete setup before the final page.
Completion flushes native settings before writing onboarding completion.

Validated QML parsing, Welcome and qmldir audits; on headless Sway/Qt software,
close at step zero leaves Welcome open, IPC traverses steps 1–4, completion stays
false until explicit close on step four, then the state file contains completed.
No Welcome errors observed. Physical input and Hyprland GPU checks remain open.
Umbrella audit still fails at the pre-existing DesktopWidgetHost source assertion;
pre-existing Privacy warnings remain in the diagnostic runtime.
