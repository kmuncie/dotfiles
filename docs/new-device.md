# New Mac Setup

Checklist for setting up a fresh Macbook with this repo. Scriptable steps are
automated by `bootstrap.sh` and `macos-defaults.sh`; the rest are GUI/account
steps that can't be scripted.

## 1. Before anything

- Sign into **iCloud** (System Settings → Apple ID).
- Sign into the **App Store** (needed if you use `mas` entries in the Brewfile).
- Connect to Wi-Fi.

## 2. Run the bootstrap

A brand-new Mac has **no git**, so you can't clone this repo yet. You don't need
to — `curl` (part of base macOS) fetches the bootstrap script directly from
GitHub, and the script clones the repo itself once it has installed a
brew-managed git:

```bash
curl -fsSL https://raw.githubusercontent.com/kmuncie/dotfiles/master/bootstrap.sh -o /tmp/bootstrap.sh
bash /tmp/bootstrap.sh personal
```

This installs Xcode Command Line Tools, Homebrew, a brew-managed git, clones the
repo to `~/dotfiles`, installs all Brewfile packages and dotfile symlinks, and
sets zsh as the default shell.

If it stops after installing Command Line Tools, finish the GUI installer and
re-run the same two commands — it's idempotent.

> Why not just `git clone` first? A fresh Mac has no git until either Xcode CLT
> or Homebrew installs one. Rather than lean on Apple's CLT git, the bootstrap
> installs git via Homebrew and clones with that — see the note in the README.

Once the repo is cloned, the remaining steps run from inside it (`cd ~/dotfiles`).

## 3. Apply macOS system preferences

```bash
./macos-defaults.sh
```

Sets keyboard repeat, Finder, Dock, screenshots, and window behavior. Log out
and back in for anything that doesn't apply immediately. Review the script first
— a few items (require-password-after-sleep, battery %) are commented out for
you to opt into.

## 4. tmux plugins

TPM is cloned automatically by `bootstrap.sh`. Open tmux and press `Ctrl+B I`
(capital i) to install plugins (catppuccin, tmux-sensible, tmux-resurrect).

## 5. Theme post-install

The bootstrap runs `bat cache --build` automatically, but if you need to rerun it:

```bash
bat cache --build   # registers the Catppuccin Mocha bat theme
```

**Obsidian:** Settings → Appearance → Themes → Browse → search "Catppuccin" →
install. Select "Catppuccin" and choose the Mocha flavor.

## 6. SSH key via 1Password

SSH auth uses a key stored in 1Password and served by its built-in SSH agent
(Touch ID per use, no private key on disk, synced across devices). The bootstrap
clones over HTTPS, so this is only needed for pushing.

1. **Install + sign into 1Password** (the Brewfile installs it).
2. **Enable the agent:** 1Password → Settings → Developer → turn on
   *"Use the SSH agent"* (and *"Integrate with 1Password CLI"* if you want `op`).
3. **Create the key:** 1Password → New Item → SSH Key → generate an Ed25519 key.
4. **Point SSH at the 1Password agent.** Add to `~/.ssh/config`:
   ```
   Host *
     IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
   ```
5. **Add the public key to GitHub:** copy it from 1Password → github.com →
   Settings → SSH and GPG keys → New SSH key (Authentication type). Or:
   `op item get "GitHub SSH" --fields public_key | gh ssh-key add -`
6. **Switch the repo remote to SSH:**
   ```bash
   git -C ~/dotfiles remote set-url origin git@github.com:kmuncie/dotfiles.git
   ```
7. **Test:** `ssh -T git@github.com` → should greet you by username.

SSH auth lives in 1Password; GPG/YubiKey (next) stays for commit *signing* —
two separate identities.

## 7. GPG / YubiKey commit signing

Follow [`docs/gpg-guide.md`](gpg-guide.md) and the
[YubiKey-Guide](https://github.com/drduh/YubiKey-Guide). Verify with:

```bash
echo "test" | gpg --clearsign
git config --get user.signingkey
```

## 8. App sign-ins & GUI-only settings

These can't be scripted — do them by hand:

- **1Password** — sign in, enable browser + CLI integration (`op`).
- **Nextcloud** — connect and pick sync folders.
- **Chrome** — sign in, sync extensions.
- **Slack / Discord / Teams / Zoom / Spotify** — sign in.
- **Obsidian** — open your vault (synced via Nextcloud/iCloud).
- **Rectangle / Maccy / BetterDisplay** — grant Accessibility permissions
  (System Settings → Privacy & Security → Accessibility) and set to launch at login.
- **iTerm2 / WezTerm** — confirm color scheme and font render correctly.

### Apps not covered by Brewfile / mas

Install these by hand — no working cask or `mas` entry:

- **JW Library** — Mac App Store (doesn't resolve via `mas search`).
- **Xcode** — Apple Developer download or `xcodes`, not mas (commented in Brewfile).
- **Exodus**, **TinkerTool** — direct download from the vendor.
- **Ivanti Secure Access** — work-provided VPN client.
- **Jagex Launcher**, **OpenTTD** — game launchers, direct download.

## 9. Verify

- Open a fresh terminal — prompt (oh-my-posh), aliases, and PATH should all work.
- `brew doctor` should be clean.
- `nvim` opens and LazyVim finishes syncing plugins on first launch.

## Updating later

Editing existing dotfiles is picked up immediately (they're symlinks). Re-run
`./install.sh personal` only when a **new file** is added to a stow package.
