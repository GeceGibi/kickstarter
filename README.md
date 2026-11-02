# runner-setup

## Host

On the host Mac, once:

```sh
./kickstarter-host/install.sh
```

That registers a login service. It clones `base-macos` to `ci-macos`, runs only the clone, and deletes the clone when it stops. Ten seconds later it clones again. `base-macos` is never started.

The control terminal keeps one line up to date: how long `ci-macos` has been up and `clone`, the disk the clone holds on top of `base-macos`. That is what deleting the clone frees. `du` would show the whole base image, because an APFS clone shares its blocks with `base-macos`; `private-size.py` counts only the blocks the clone owns.

`v` opens or hides the picture. The VM keeps running. `k` or Control+C stops and deletes the clone and leaves it stopped until `install.sh` is run again.

## VM

Once, while building `base-macos`:

```sh
./kickstarter-vm/install.sh
```

Put one absolute path per line in `kickstarter-vm/paths` before saving the image. Every clone starts that service at login. If a program exits, it is started again after 10 seconds. The VM can stay up for months.

A Python app, or any startup that is more than one command, is one script. Copy `kickstarter-vm/job.template`, edit it, and put that copy's absolute path in `paths`. One path, one window. After the script exits, it runs again from the top.
