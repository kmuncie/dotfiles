# From https://github.com/jthomerson/dotfiles


# ==> php@7.1
# To enable PHP in Apache add the following to httpd.conf and restart Apache:
# LoadModule php7_module /usr/local/opt/php@7.1/lib/httpd/modules/libphp7.so
#
# <FilesMatch \.php$>
# SetHandler application/x-httpd-php
# </FilesMatch>
#
# Finally, check DirectoryIndex includes index.php
# DirectoryIndex index.php index.html
#
# The php.ini and php-fpm.ini file can be found in:
# /usr/local/etc/php/7.1/
#
# php@7.1 is keg-only, which means it was not symlinked into /usr/local,
# because this is an alternate version of another formula.
#
# If you need to have php@7.1 first in your PATH run:
# echo 'export PATH="/usr/local/opt/php@7.1/bin:$PATH"' >> ~/.bash_profile
# echo 'export PATH="/usr/local/opt/php@7.1/sbin:$PATH"' >> ~/.bash_profile
#
# For compilers to find php@7.1 you may need to set:
# export LDFLAGS="-L/usr/local/opt/php@7.1/lib"
# export CPPFLAGS="-I/usr/local/opt/php@7.1/include"
#
#
# To have launchd start php@7.1 now and restart at login:
#    brew services start php@7.1
# Or, if you don't want/need a background service you can just run:
#    php-fpm
export PATH="/usr/local/opt/php@7.3/bin:$PATH"
export PATH="/usr/local/opt/php@7.3/sbin:$PATH"


# From `brew install coreutils`:
# ==> Pouring coreutils-8.31.mojave.bottle.tar.gz
# ==> Caveats
# Commands also provided by macOS have been installed with the prefix "g".
# If you need to use these commands with their normal names, you
# can add a "gnubin" directory to your PATH from your bashrc like:
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"


# From `brew install grep`:
# ==> Pouring grep-3.3.mojave.bottle.2.tar.gz
# ==> Caveats
# All commands have been installed with the prefix "g".
# If you need to use these commands with their normal names, you
# can add a "gnubin" directory to your PATH from your bashrc like:
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"


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
export PATH="/usr/local/opt/python/libexec/bin:$PATH"
export PATH="/usr/local/opt/python35/bin:$PATH"


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
export PATH="/usr/local/opt/openssl/bin:$PATH"


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
export PATH="/usr/local/opt/sqlite/bin:$PATH"


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
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="$PATH:~/.gem/bin"

# From `brew cask install mactex`
# Not explicitly stated in the install, but you need to add its bin
# folder to the PATH:
if [ -d /Library/TeX/texbin ]; then
   export PATH="/Library/TeX/texbin:$PATH"
fi

# WSL Yarn added to PATH https://github.com/yarnpkg/yarn/issues/5353
if [ -d ~/.yarn/bin ]; then
   export PATH="$(yarn global bin):$PATH"
fi
