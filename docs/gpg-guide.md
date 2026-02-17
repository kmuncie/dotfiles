# GPG Quick Reference

Personal reference for GPG encryption/decryption using a YubiKey-backed key.

## Setup

The GPG key ID is exported in `personal/.profile`:

```bash
export GPG_TTY=$(tty)
export KEYID="C37CD320884F61A9"
```

The private key lives on a YubiKey. If the YubiKey isn't inserted when GPG
needs it, you'll be prompted to insert the card before continuing.

## Shell Aliases (from `common/.aliases`)

### `secret <file>` — Encrypt a file to yourself

```bash
secret notes.txt
# Output: notes.txt.1739836200.enc
```

Encrypts the file using your public key (`$KEYID`). Only your YubiKey can
decrypt it. The output filename includes a Unix timestamp.

### `reveal <file>` — Decrypt a file

```bash
reveal notes.txt.1739836200.enc
# Output: notes.txt
```

Strips the `.TIMESTAMP.enc` suffix and decrypts the file. Requires the
YubiKey to be inserted and your PIN.

## Exchanging Encrypted Messages with Others

### Sharing your public key

Before someone can send you an encrypted message, they need your public key:

```bash
# Export your public key to a file
gpg --export --armor kevin@kmuncie.com > kevin-public-key.asc

# Or copy it directly to clipboard (macOS)
gpg --export --armor kevin@kmuncie.com | pbcopy
```

You can share this `.asc` file or pasted text freely — it's public information.
Post it on Reddit, email it, put it on a website, etc.

### Importing someone else's public key

If someone provides you their public key (a block of text starting with
`-----BEGIN PGP PUBLIC KEY BLOCK-----`):

```bash
# Import from a file
gpg --import their-key.asc

# Or paste directly (Ctrl+D to finish)
gpg --import
```

### Looking up a key on a keyserver

If someone gives you their key ID or email instead of a key file:

```bash
# Search by email
gpg --keyserver keyserver.ubuntu.com --search-keys user@example.com

# Fetch by key ID
gpg --keyserver keyserver.ubuntu.com --recv-keys THEIR_KEY_ID
```

### Verifying an imported key

After importing, verify the fingerprint out-of-band (e.g. the person confirms
it on Reddit, their website, Twitter, etc.):

```bash
gpg --fingerprint their@email.com
```

Optionally sign the key to mark it as trusted locally:

```bash
gpg --lsign-key their@email.com
```

### Encrypting a message to someone else

```bash
# Encrypt a file for a specific recipient
gpg --encrypt --armor --output message.enc -r their@email.com message.txt

# Encrypt for both them AND yourself (so you can also decrypt it later)
gpg --encrypt --armor --output message.enc -r their@email.com -r kevin@kmuncie.com message.txt
```

### Decrypting a message someone sent you

If someone encrypted a message to your public key:

```bash
# Decrypt to stdout
gpg --decrypt message.enc

# Decrypt to a file
gpg --decrypt --output message.txt message.enc
```

YubiKey must be inserted. You'll be prompted for your PIN.

### Encrypting a quick text message (no file needed)

```bash
# Type or paste a message, then Ctrl+D to encrypt
gpg --encrypt --armor -r their@email.com | pbcopy
```

This puts the encrypted message on your clipboard, ready to paste into Reddit,
email, etc.

### Decrypting a text message (no file needed)

```bash
# Paste the PGP message block, then Ctrl+D to decrypt
gpg --decrypt
```

## Common Scenarios

### Reddit DM exchange

1. The other person posts or sends you their public key
2. `gpg --import their-key.asc`
3. Write your message in a file or encrypt directly:
   `echo "secret message" | gpg --encrypt --armor -r their@email.com | pbcopy`
4. Paste the encrypted block into Reddit
5. To read their reply: copy the PGP block, run `gpg --decrypt`, paste, Ctrl+D

### Verify your YubiKey is connected

```bash
gpg --card-status
```

### List your keys

```bash
# Your keys
gpg --list-keys --keyid-format long

# Keys you've imported
gpg --list-keys
```
