# runner-setup

## Host

On the host Mac, once:

```sh
./kickstarter-host/install.sh
```

That registers a login service. It clones `base-macos` to `ci-macos`, runs only the clone, and deletes the clone when it stops. Ten seconds later it clones again. `base-macos` is never started.

## VM

Inside the VM:

```sh
./setup.sh
```

That registers `kickstarter-vm`. Add one absolute path per line in `kickstarter-vm/paths`. The next login reads that file.
