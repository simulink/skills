#!/bin/bash
# setup_fmusim.sh
# Downloads and extracts fmusim from the Reference-FMUs project.

set -e

FMUSIM="/tmp/fmusim-x86_64-linux/fmusim"

if [ ! -x "$FMUSIM" ]; then
    echo "Downloading Reference-FMUs release to get fmusim..."
    curl -sL "https://api.github.com/repos/modelica/Reference-FMUs/releases/latest" \
      | python3 -c "import json,sys; print([a['browser_download_url'] for a in json.load(sys.stdin)['assets'] if a['name'].startswith('Reference-FMUs')][0])" \
      | xargs curl -sL -o /tmp/refmus.zip
    
    echo "Extracting fmusim..."
    unzip -o /tmp/refmus.zip "fmusim-x86_64-linux/fmusim" -d /tmp/
    chmod +x "$FMUSIM"
    echo "fmusim setup complete at $FMUSIM"
else
    echo "fmusim already installed at $FMUSIM"
fi
