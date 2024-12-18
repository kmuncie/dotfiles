export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# From https://github.com/jthomerson/dotfiles

# From `brew install coreutils`:
# ==> Pouring coreutils-8.31.mojave.bottle.tar.gz
# ==> Caveats
# Commands also provided by macOS have been installed with the prefix "g".
# If you need to use these commands with their normal names, you
# can add a "gnubin" directory to your PATH from your bashrc like:
# https://stackoverflow.com/questions/57972341/how-to-install-and-use-gnu-ls-on-macos
export PATH="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin:${PATH}"
export MANPATH="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnuman:${MANPATH}"


# From `brew install grep`:
# ==> Pouring grep-3.3.mojave.bottle.2.tar.gz
# ==> Caveats
# All commands have been installed with the prefix "g".
# If you need to use these commands with their normal names, you
# can add a "gnubin" directory to your PATH from your bashrc like:
export PATH="${HOMEBREW_PREFIX}/opt/grep/libexec/gnubin:$PATH"


# From `brew install python` (or, because `python` is dependency of `ffmpeg`)
# ==> Pouring python-3.7.3.mojave.bottle.1.tar.gz
# ==> Caveats
# Python has been installed as
#   /usr/local/bin/python3
#
# Unversioned symlinks `python`, `python-config`, `pip` etc. pointing to
# `python3`, `python3-config`, `pip3` etc., respectively, have been installed into
#   /usr/local/opt/python/libexec/bin
#
# If you need Homebrew's Python 2.7 run
#   brew install python@2
#
# You can install Python packages with
#   pip3 install <package>
# They will install into the site-package directory
#   /usr/local/lib/python3.7/site-packages
#
# See: https://docs.brew.sh/Homebrew-and-Python
export PATH="${HOMEBREW_PREFIX}/opt/python/libexec/bin:$PATH"



# From `brew install openssl` (or, because `openssl` is dependency of `ffmpeg`)
# ==> Caveats
# A CA file has been bootstrapped using certificates from the SystemRoots
# keychain. To add additional certificates (e.g. the certificates added in
# the System keychain), place .pem files in
#   /usr/local/etc/openssl/certs
#
# and run
#   /usr/local/opt/openssl/bin/c_rehash
#
# openssl is keg-only, which means it was not symlinked into /usr/local,
# because Apple has deprecated use of OpenSSL in favor of its own TLS and crypto libraries.
#
# If you need to have openssl first in your PATH run:
#   echo 'export PATH="/usr/local/opt/openssl/bin:$PATH"' >> ~/.bash_profile
#
# For compilers to find openssl you may need to set:
#   export LDFLAGS="-L/usr/local/opt/openssl/lib"
#   export CPPFLAGS="-I/usr/local/opt/openssl/include"
# export PATH="/usr/local/opt/openssl/bin:$PATH"

# From `brew install openssl@1.1`
# A CA file has been bootstrapped using certificates from the system
# keychain. To add additional certificates, place .pem files in
#   /usr/local/etc/openssl@1.1/certs
#
# and run
#   /usr/local/opt/openssl@1.1/bin/c_rehash
#
# openssl@1.1 is keg-only, which means it was not symlinked into /usr/local,
# because openssl/libressl is provided by macOS so don't link an incompatible version.
#
# If you need to have openssl@1.1 first in your PATH run:
#   echo 'export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"' >> ~/.bash_profile
#
# For compilers to find openssl@1.1 you may need to set:
#   export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
#   export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
export PATH="${HOMEBREW_PREFIX}/opt/openssl@1.1/bin:$PATH"


# From `brew install readline` (or, because `readline` is dependency of `ffmpeg`)
# ==> Pouring readline-8.0.0_1.mojave.bottle.tar.gz
# ==> Caveats
# readline is keg-only, which means it was not symlinked into /usr/local,
# because macOS provides the BSD libedit library, which shadows libreadline.
# In order to prevent conflicts when programs look for libreadline we are
# defaulting this GNU Readline installation to keg-only.
#
# For compilers to find readline you may need to set:
#   export LDFLAGS="-L/usr/local/opt/readline/lib"
#   export CPPFLAGS="-I/usr/local/opt/readline/include"


# From `brew install sqlite`
# ==> Pouring sqlite-3.28.0.mojave.bottle.tar.gz
# ==> Caveats
# sqlite is keg-only, which means it was not symlinked into /usr/local,
# because macOS provides an older sqlite3.
#
# If you need to have sqlite first in your PATH run:
#   echo 'export PATH="/usr/local/opt/sqlite/bin:$PATH"' >> ~/.bash_profile
#
# For compilers to find sqlite you may need to set:
#   export LDFLAGS="-L/usr/local/opt/sqlite/lib"
#   export CPPFLAGS="-I/usr/local/opt/sqlite/include"
export PATH="${HOMEBREW_PREFIX}/opt/sqlite/bin:$PATH"


# From `brew install ruby` (or, because `ruby` is a dependency of `vim`)
# ==> ruby
# By default, binaries installed by gem will be placed into:
#   /usr/local/lib/ruby/gems/2.6.0/bin
#
# You may want to add this to your PATH.
#
# ruby is keg-only, which means it was not symlinked into /usr/local,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.
#
# If you need to have ruby first in your PATH run:
#   echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.bash_profile
#
# For compilers to find ruby you may need to set:
#   export LDFLAGS="-L/usr/local/opt/ruby/lib"
#   export CPPFLAGS="-I/usr/local/opt/ruby/include"
export PATH="${HOMEBREW_PREFIX}/opt/ruby/bin:$PATH"


# From `brew cask install mactex`
# Not explicitly stated in the install, but you need to add its bin
# folder to the PATH:
if [ -d /Library/TeX/texbin ]; then
   export PATH="/Library/TeX/texbin:$PATH"
fi

# From `brew install openjdk`
# ==> Pouring openjdk-13.0.2+8_2.mojave.bottle.tar.gz
# ==> Caveats
# For the system Java wrappers to find this JDK, symlink it with
#   sudo ln -sfn /usr/local/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
#
# openjdk is keg-only, which means it was not symlinked into /usr/local,
# because it shadows the macOS `java` wrapper.
#
# If you need to have openjdk first in your PATH run:
#   echo 'export PATH="/usr/local/opt/openjdk/bin:$PATH"' >> ~/.bash_profile
#
# For compilers to find openjdk you may need to set:
#   export CPPFLAGS="-I/usr/local/opt/openjdk/include"
#
# ==> Summary
# 🍺  /usr/local/Cellar/openjdk/13.0.2+8_2: 631 files, 314.6MB
export PATH="${HOMEBREW_PREFIX}/opt/openjdk/bin:$PATH"

# From `brew install gnu-sed`
# ==> Pouring gnu-sed-4.8.mojave.bottle.tar.gz
# ==> Caveats
# GNU "sed" has been installed as "gsed".
# If you need to use it as "sed", you can add a "gnubin" directory
# to your PATH from your bashrc like:
#
#     PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
PATH="${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin:$PATH"

## -- Kevin's Additions ------------------------------------------------

# From `brew cask install mactex`
# Not explicitly stated in the install, but you need to add its bin
# folder to the PATH:
if [ -d /Library/TeX/texbin ]; then
   export PATH="/Library/TeX/texbin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
   PATH="$HOME/bin:$PATH"
fi

# Setup Go PATH variables https://linode.com/docs/development/go/install-go-on-ubuntu/
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Setup Flutter PATH variable
export PATH=$PATH:/home/kmuncie/flutter/bin

export PATH=${PATH}:./node_modules/.bin

# Homebrew checks for Linux, MacOS M1, MacOS x86
if [ -d "/home/linuxbrew/" ]; then
   eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
elif [ -f /opt/homebrew/bin/brew ]; then
   eval $(/opt/homebrew/bin/brew shellenv)
elif [ -f /usr/local/bin/brew ]; then
   eval $(/usr/local/bin/brew shellenv)
fi
