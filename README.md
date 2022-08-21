# kizzycode/jekyll

`kizzycode/jekyll` is a minimal docker container that provides support for an automated
`git-over-ssh -> jekyll build -> thttpd serve`-workflow.

## Internal workflow
On startup, the container creates a bare git repository in `/home/jekyll/git` (associated remote:
`ssh://jekyll@SERVER_ADDR/~/git`). Then it injects a `post-receive`-hook for this repo which gets invoked after a
successful `git push` operation – once the data has been pushed, the hook invokes `bundle exec jekyll build` to build
the site. If the site was built successfully, it is copied into the webroot where it gets served.

## Example
See [Docker-Compose.yml](Docker-Compose.yml) for example configuration.
