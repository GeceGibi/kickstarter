# runner-setup

## Kickstarter

macOS host application that runs services from `kickstarter/paths` in the background without opening Terminal windows, tracks uptime, and provides an on-demand live log viewer.

```sh
cd kickstarter
flutter run -d macos
```

- **Add File**: Opens the native macOS file picker and saves selected script paths to the gitignored `kickstarter/paths` file.
- **Process Supervision**: Each path in `kickstarter/paths` is started after sourcing `~/.zprofile` and automatically restarts 10 seconds after exit.
- **Uptime & Logs**: Displays live uptime for each running service and opens an on-demand `stdout`/`stderr` log panel when **Logs** is clicked.
- **Login Agent**: The **Install Login Agent** button (or `--install` CLI flag) registers `~/Library/LaunchAgents/kickstarter.plist` to start at login.
