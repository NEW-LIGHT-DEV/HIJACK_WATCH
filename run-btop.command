#!/bin/bash

# Launch btop system monitor
# Note: This script brings btop to foreground constantly and interferes with cursor control
# Disabled in production due to UI interference issues

# Uncomment to enable btop (not recommended for headless operation):
# /opt/homebrew/bin/btop

echo "btop disabled due to cursor control and modal stacking issues"
echo "Use only for manual system monitoring when user is present"
