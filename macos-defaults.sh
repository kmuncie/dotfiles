#!/usr/bin/env bash
# Applies macOS system preferences via `defaults write` for a fresh machine.
# Idempotent — safe to re-run. Some changes need a logout to fully apply.

set -euo pipefail

echo "Applying macOS defaults. Some changes require logout/restart to take effect."

# Close System Settings so it doesn't overwrite values we're about to change.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# ------------------------------------------------------------------------------
# Keyboard
# Fast key repeat + short delay (big win for vim/nvim navigation).
# Accent press-and-hold popup is left ENABLED (ApplePressAndHoldEnabled untouched)
# so held keys still produce accented characters.
# ------------------------------------------------------------------------------
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Text "corrections" that fight with writing code. Comment any you want back.
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false   # smart quotes -> break pasted code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# ------------------------------------------------------------------------------
# Trackpad
# ------------------------------------------------------------------------------
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Three-finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# ------------------------------------------------------------------------------
# Finder
# ------------------------------------------------------------------------------
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true              # show hidden files
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"       # list view
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"       # search current folder
defaults write com.apple.finder _FXSortFoldersFirst -bool true            # folders on top
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # no .DS_Store on network shares
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true      # no .DS_Store on USB

# ------------------------------------------------------------------------------
# Dock
# ------------------------------------------------------------------------------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0          # no delay before showing
defaults write com.apple.dock autohide-time-modifier -float 0.4  # faster show/hide animation
defaults write com.apple.dock tilesize -int 42                # smaller icons
defaults write com.apple.dock show-recents -bool false        # no recent apps section
defaults write com.apple.dock mru-spaces -bool false          # don't auto-rearrange Spaces

# ------------------------------------------------------------------------------
# Screenshots
# ------------------------------------------------------------------------------
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture show-thumbnail -bool false  # no floating thumbnail

# ------------------------------------------------------------------------------
# System / windows
# ------------------------------------------------------------------------------
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true            # 24-hour clock
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false # save to disk, not iCloud, by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true # expand save panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true    # expand print panel by default
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001               # faster window resize animation
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false          # don't reopen windows after quit/reboot

# ------------------------------------------------------------------------------
# Optional — left commented; uncomment to enable.
# ------------------------------------------------------------------------------
# Require password immediately after sleep / screensaver (security; small UX cost):
# defaults write com.apple.screensaver askForPassword -int 1
# defaults write com.apple.screensaver askForPasswordDelay -int 0
#
# Show battery percentage in menu bar:
# defaults write com.apple.controlcenter BatteryShowPercentage -bool true

# ------------------------------------------------------------------------------
# Restart affected apps so changes show immediately.
# ------------------------------------------------------------------------------
for app in Dock Finder SystemUIServer; do
    killall "$app" &> /dev/null || true
done

echo "Done. Log out and back in for any settings that didn't apply immediately."
