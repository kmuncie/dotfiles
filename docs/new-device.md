# New Mac Setup

Checklist for setting up a fresh Macbook with this repo. Scriptable steps are
automated by `bootstrap.sh` and `macos-defaults.sh`; the rest are GUI/account
steps that can't be scripted.

## 1. Before anything

- Sign into **iCloud** (System Settings → Apple ID).
- Sign into the **App Store** (needed if you use `mas` entries in the Brewfile).
- Connect to Wi-Fi.

## 2. Run the bootstrap

Installs Xcode Command Line Tools, Homebrew, all Brewfile packages, dotfile
symlinks, and sets zsh as the default shell.

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh personal
```

If it stops after installing Command Line Tools, finish the GUI installer and
re-run the same command — it's idempotent.

## 3. Apply macOS system preferences

```bash
./macos-defaults.sh
```

Sets keyboard repeat, Finder, Dock, screenshots, and window behavior. Log out
and back in for anything that doesn't apply immediately. Review the script first
— a few items (require-password-after-sleep, battery %) are commented out for
you to opt into.

## 4. tmux plugins

Open tmux and press `prefix + I` (capital i) to install plugins via TPM.

## 5. GPG / YubiKey commit signing

Follow [`docs/gpg-guide.md`](gpg-guide.md) and the
[YubiKey-Guide](https://github.com/drduh/YubiKey-Guide). Verify with:

```bash
echo "test" | gpg --clearsign
git config --get user.signingkey
```

## 6. App sign-ins & GUI-only settings

These can't be scripted — do them by hand:

- **1Password** — sign in, enable browser + CLI integration (`op`).
- **Nextcloud** — connect and pick sync folders.
- **Chrome** — sign in, sync extensions.
- **Slack / Discord / Teams / Zoom / Spotify** — sign in.
- **Obsidian** — open your vault (synced via Nextcloud/iCloud).
- **Rectangle / Maccy / BetterDisplay** — grant Accessibility permissions
  (System Settings → Privacy & Security → Accessibility) and set to launch at login.
- **iTerm2 / WezTerm** — confirm color scheme and font render correctly.

## 7. Verify

- Open a fresh terminal — prompt (oh-my-posh), aliases, and PATH should all work.
- `brew doctor` should be clean.
- `nvim` opens and LazyVim finishes syncing plugins on first launch.

## Updating later

Editing existing dotfiles is picked up immediately (they're symlinks). Re-run
`./install.sh personal` only when a **new file** is added to a stow package.
