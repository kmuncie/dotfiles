# Homebrew dependency manifest for the personal macOS profile.
# Install with `brew bundle`. Transitive build deps are intentionally omitted —
# Homebrew pulls them in automatically as dependencies of the formulae below.

# ------------------------------------------------------------------------------
# Taps
# ------------------------------------------------------------------------------
tap "apple/apple", "http://github.com/apple/homebrew-apple"
tap "common-fate/granted"
tap "homebrew/services"
tap "jandedobbeleer/oh-my-posh"
tap "teamookla/speedtest"

# ------------------------------------------------------------------------------
# Shell / dotfile tooling
# ------------------------------------------------------------------------------
brew "antidote"               # zsh plugin manager (.zshrc)
brew "bash"                   # modern bash (macOS ships 3.2)
brew "bash-completion"
brew "stow"                   # symlink manager (install.sh)
brew "jandedobbeleer/oh-my-posh/oh-my-posh", link: false  # prompt theme

# ------------------------------------------------------------------------------
# Core CLI replacements (GNU tools + modern alternatives)
# ------------------------------------------------------------------------------
brew "coreutils"             # GNU ls/dircolors (.dir-colors)
brew "gnu-sed"
brew "grep"                  # GNU grep
brew "bat"                   # cat with syntax highlighting
brew "fd"                    # find alternative
brew "ripgrep"               # rg
# brew "the_silver_searcher" # ag — superseded by ripgrep; re-enable if you want the `ag` alias
brew "fzf"                   # fuzzy finder
brew "jq"                    # JSON processor
brew "wget"
brew "rename"

# ------------------------------------------------------------------------------
# Editors / multiplexer
# ------------------------------------------------------------------------------
brew "neovim"                # LazyVim config in .config/nvim
brew "vim"
brew "tmux"

# ------------------------------------------------------------------------------
# Git / version control
# ------------------------------------------------------------------------------
brew "git"
brew "git-delta"             # diff pager (.gitconfig)
brew "gh"                    # GitHub CLI

# ------------------------------------------------------------------------------
# GPG / YubiKey commit signing
# ------------------------------------------------------------------------------
brew "gnupg"
brew "pinentry-mac"
brew "ykman"
brew "ykpers"

# ------------------------------------------------------------------------------
# Cloud / infra
# ------------------------------------------------------------------------------
brew "awscli"
brew "azure-cli"
brew "common-fate/granted/granted"  # AWS role assumption (assume function)
brew "teamookla/speedtest/speedtest"
brew "iperf3"

# ------------------------------------------------------------------------------
# Languages / build toolchains
# ------------------------------------------------------------------------------
brew "go"
brew "uv"                    # python package manager (manages its own pythons)
# brew "python@3.9"          # EOL; uv handles pythons now — re-enable if a tool pins 3.9
# brew "ruby"                # only needed for cocoapods below
# brew "cocoapods"           # legacy iOS dep manager, superseded by Swift Package Manager
# brew "llvm@16"             # old pinned LLVM, likely a stale build dep — re-enable if a build needs it
brew "cmake"
# brew "automake"            # autotools build dep, rarely used standalone
# brew "bison"               # parser generator build dep, rarely used standalone

# ------------------------------------------------------------------------------
# Media / documents / fonts
# ------------------------------------------------------------------------------
brew "ffmpeg"
brew "imagemagick"
brew "yt-dlp"
brew "pandoc"
brew "poppler"               # pdftotext, pdfinfo
brew "csvkit"
# brew "epubcheck"           # ebook validator — niche, re-enable for epub work
# brew "fontforge"           # font editor — niche, re-enable for font work
# brew "ttfautohint"         # font hinting — niche, pairs with fontforge

# ------------------------------------------------------------------------------
# Misc
# ------------------------------------------------------------------------------
# brew "neofetch"           # discontinued upstream (2024) — consider `fastfetch`; `neofetch` alias breaks until re-enabled
brew "mas"                   # Mac App Store CLI (for mas entries below)

# ------------------------------------------------------------------------------
# Casks (GUI apps)
# ------------------------------------------------------------------------------
cask "1password"
cask "1password-cli"
cask "anki"
cask "artisan"
cask "balenaetcher"
cask "betterdisplay"
cask "calibre"
cask "claude-code"
cask "discord"
cask "docker-desktop"
cask "google-chrome"
cask "grandperspective"
cask "imageoptim"
cask "iterm2"
cask "maccy"
cask "mactex"
cask "microsoft-auto-update"
cask "microsoft-teams"
cask "nextcloud"
cask "obsidian"
cask "orbstack"
cask "rectangle"
cask "runelite"
cask "slack"
cask "spotify"
cask "visual-studio-code"
cask "vlc"
cask "wezterm"
cask "xld"
cask "zoom"

# ------------------------------------------------------------------------------
# Mac App Store apps (require `mas` + signed-in App Store)
# Find IDs with: mas search "App Name"
# ------------------------------------------------------------------------------
# mas "Xcode", id: 497799835
