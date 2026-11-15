# Releasing

CurseForge packages releases from this repository when a new tag is pushed. Configure its GitHub integration to build tags only. GitHub Actions checks the code and package, but does not publish anything. No CurseForge API key is needed in GitHub.

## Setup

1. Connect `joachimtingvold/ahdb-auctionator-sync` through the CurseForge project's repository integration and enable packaging for tags only. Adding a project-page link alone does not enable packaging.
2. Check that AHDB and Auctionator are listed as required dependencies. These are also declared in `.pkgmeta`.
3. Wait for GitHub CI to pass before publishing.

## Publish a release

Update `CHANGELOG.md`, commit and push the changes, then tag the commit you want to release. For the first release:

```sh
git switch main
git pull --ff-only
git tag -a v0.3.0-beta -m "Release v0.3.0-beta"
git push origin v0.3.0-beta
```

A tag can point to an existing commit; no extra code change is needed. Enable the CurseForge integration before pushing the tag.

Use a tag such as `v0.3.1` for a stable release or `v0.4.0-beta.1` for a beta. Do not move a tag after publishing it.

Check CurseForge's build log and Files page after tagging. A successful build may still need moderation before it becomes public.

## Changelog

`.pkgmeta` tells the packager to use `CHANGELOG.md` for release notes. The whole file is used, including previous entries. The tag message is not the changelog.

Keep `@project-version@` in the source TOC. The packager replaces it with the tag when building the addon.

## If a manual upload is needed

A first tagged build does not normally need a previous upload. If CurseForge requests a file for project approval:

1. Upload the installable addon ZIP, with the `AHDBAuctionatorSync` folder inside it. Do not use the repository source ZIP.
2. Choose the release type and supported game version, and paste the release notes from `CHANGELOG.md`.
3. Check the required dependencies and submit for review.

If that version is published manually, use a new version and tag for the next automated release to avoid duplicates. If automatic packaging fails, check its build log first.

## Local checks

Run from the repository root with Lua 5.1 installed:

```sh
luac5.1 -p AHDBAuctionatorSync.lua tests/test_sync.lua
lua5.1 tests/test_sync.lua
```

CI also builds and checks an installable ZIP without uploading it. Its `addon-test-package` artifact contains that ZIP inside GitHub's download wrapper. The tests use mocked AHDB and Auctionator APIs; they do not run the game client.
