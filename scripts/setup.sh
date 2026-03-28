#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Clone all repos
pushd "$ROOT_DIR"
multi sync
popd

# Set up Python workspace dependencies
cat > ${ROOT_DIR}/web/workspace_requirements.txt << EOF
-e ../camera-roll-sounds-api
EOF

# Call the web setup script
pushd ${ROOT_DIR}/web
./scripts/setup
popd

# Call the React install scripts
pushd ${ROOT_DIR}/camera-roll-sounds-react
npm install
popd

# Prepare the iOS project dependencies
pushd ${ROOT_DIR}/camera-roll-sounds-ios
tuist install
popd

echo "Setup complete! Please restart your IDE, then you can run your project with the VS Code run button."
