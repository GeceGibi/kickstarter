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

Run `./kickstart/install.sh` once. It registers `kickstart.sh` as the login agent.

Add one absolute path per line in `kickstart/paths`. The next login reads that file. A new path does not need install again.
