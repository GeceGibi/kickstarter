# Kickstarter

macOS host application that runs services from `~/.kickstarter/{worker,git-actions}/paths.json` in the background without opening Terminal windows, tracks uptime, and provides an on-demand live log viewer.

```sh
flutter run -d macos
```

- **Add Worker / Add Git-Action**: Opens the native macOS file picker and saves selected script/executable paths to `~/.kickstarter/worker/paths.json` or `~/.kickstarter/git-actions/paths.json`.
- **Process Supervision**: Each configured path is started after sourcing `~/.zprofile` and automatically restarts 10 seconds after exit.
- **Uptime & Logs**: Displays live uptime for each running service and opens an on-demand `stdout`/`stderr` log panel when **Logs** is clicked.
- **Login Agent**: The **Install Login Agent** button (or `--install` CLI flag) registers `~/Library/LaunchAgents/kickstarter.plist` to start at login.
