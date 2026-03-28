# camera-roll-sounds

## Getting started

This repo is the workspace repo for a `multi` setup. The app code lives in separate git repos checked out into these project directories:

- `web`
- `camera-roll-sounds-api`
- `camera-roll-sounds-ios`
- `camera-roll-sounds-react`
- `ios-shared`

To get started, install `multi` with `uv tool install multi-workspace`.

Then install the [extension](https://marketplace.visualstudio.com/items?itemName=montaguegabe.multi-workspace) in Cursor or VS Code. When you update shared VS Code or Cursor sync inputs in one of the project directories, run `multi sync` to regenerate the root workspace files.
