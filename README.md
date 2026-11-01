# runner-setup

Apple Silicon bootstrap for a Mac that builds Flutter iOS and Android.

## Setup

```sh
./setup.sh
```

Re-run after a format. Tools that are already installed are left in place.

Flutter goes to `$HOME/dev/flutter`. `setup.sh` writes `$HOME/dev/env.sh` and sources it from `~/.zshrc`. Open a new terminal after it finishes.

Xcode.app, signing certificates, and the GitHub Actions runner registration are not installed by this script.

## Login startup

Add one absolute path per line in `kickstart/paths`, then:

```sh
./kickstart/install.sh
```

Each path that exists opens in a Terminal window at login.
