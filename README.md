# runner-setup

## Host

On the host Mac, once:

```sh
./kickstarter-host/install.sh
```

That registers a login service. It clones `base-macos` to `ci-macos`, runs only the clone, and deletes the clone when it stops. Ten seconds later it clones again. `base-macos` is never started. Screen Sharing opens on its own when the picture is ready. In the control terminal, `v` hides or shows it. The VM keeps running.

## VM

Once, while building `base-macos`:

```sh
./kickstarter-vm/install.sh
```

Put one absolute path per line in `kickstarter-vm/paths` before saving the image. Every clone starts that service at login. If a program exits, it is started again after 10 seconds. The VM can stay up for months.
