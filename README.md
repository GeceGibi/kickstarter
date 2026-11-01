# runner-setup

Apple Silicon bootstrap for a Mac that builds Flutter iOS and Android.

## Setup

```sh
./setup.sh
```

Re-run after a format. Tools that are already installed are left in place.

Flutter goes to `$HOME/dev/flutter`. Paths are written to `$HOME/dev/env.sh` and sourced from `~/.zshrc`.

Xcode.app, signing certificates, and the GitHub Actions runner registration are not installed by this script.

## Login startup

Add one absolute path per program in `kickstart/kickstart.sh`, then:

```sh
./kickstart/install.sh
```

Each path that exists opens in a Terminal window at login.

## One-time Flutter move

If Flutter is still at `$HOME/flutter`:

```sh
./migration.sh
```

Delete it after it runs.
