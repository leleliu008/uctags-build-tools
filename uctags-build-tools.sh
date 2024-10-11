#!/bin/sh

set -e

COLOR_GREEN='\033[0;32m'        # Green
COLOR_PURPLE='\033[0;35m'       # Purple
COLOR_OFF='\033[0m'             # Reset

echo() {
    printf '%b\n' "$*"
}

run() {
    echo "${COLOR_PURPLE}==>${COLOR_OFF} ${COLOR_GREEN}$@${COLOR_OFF}"
    eval "$@"
}

__setup_freebsd() {
    run $sudo pkg install -y coreutils cmake gmake gcc pkgconf

    run $sudo ln -sf /usr/local/bin/gln        /usr/bin/ln
    run $sudo ln -sf /usr/local/bin/gmake      /usr/bin/make
    run $sudo ln -sf /usr/local/bin/gstat      /usr/bin/stat
    run $sudo ln -sf /usr/local/bin/gdate      /usr/bin/date
    run $sudo ln -sf /usr/local/bin/gnproc     /usr/bin/nproc
    run $sudo ln -sf /usr/local/bin/gbase64    /usr/bin/base64
    run $sudo ln -sf /usr/local/bin/gunlink    /usr/bin/unlink
    run $sudo ln -sf /usr/local/bin/ginstall   /usr/bin/install
    run $sudo ln -sf /usr/local/bin/grealpath  /usr/bin/realpath
    run $sudo ln -sf /usr/local/bin/gsha256sum /usr/bin/sha256sum
}

__setup_openbsd() {
    run $sudo pkg_add coreutils cmake gmake gcc%11 pkgconf libarchive

    run $sudo ln -sf /usr/local/bin/gln        /usr/bin/ln
    run $sudo ln -sf /usr/local/bin/gmake      /usr/bin/make
    run $sudo ln -sf /usr/local/bin/gstat      /usr/bin/stat
    run $sudo ln -sf /usr/local/bin/gdate      /usr/bin/date
    run $sudo ln -sf /usr/local/bin/gnproc     /usr/bin/nproc
    run $sudo ln -sf /usr/local/bin/gbase64    /usr/bin/base64
    run $sudo ln -sf /usr/local/bin/gunlink    /usr/bin/unlink
    run $sudo ln -sf /usr/local/bin/ginstall   /usr/bin/install
    run $sudo ln -sf /usr/local/bin/grealpath  /usr/bin/realpath
    run $sudo ln -sf /usr/local/bin/gsha256sum /usr/bin/sha256sum
}

__setup_netbsd() {
    run $sudo pkgin -y update
    run $sudo pkgin -y install coreutils cmake gmake pkg-config bsdtar

    run $sudo ln -sf /usr/pkg/bin/gln        /usr/bin/ln
    run $sudo ln -sf /usr/pkg/bin/gmake      /usr/bin/make
    run $sudo ln -sf /usr/pkg/bin/gstat      /usr/bin/stat
    run $sudo ln -sf /usr/pkg/bin/gdate      /usr/bin/date
    run $sudo ln -sf /usr/pkg/bin/gnproc     /usr/bin/nproc
    run $sudo ln -sf /usr/pkg/bin/gbase64    /usr/bin/base64
    run $sudo ln -sf /usr/pkg/bin/gunlink    /usr/bin/unlink
    run $sudo ln -sf /usr/pkg/bin/ginstall   /usr/bin/install
    run $sudo ln -sf /usr/pkg/bin/grealpath  /usr/bin/realpath
    run $sudo ln -sf /usr/pkg/bin/gsha256sum /usr/bin/sha256sum
}

__setup_macos() {
    run brew install coreutils make
}

__setup_linux() {
    . /etc/os-release

    case $ID in
        ubuntu)
            run $sudo apt-get -y update
            run $sudo apt-get -y install curl libarchive-tools cmake make pkg-config g++ linux-headers-generic patchelf
            run $sudo ln -sf /usr/bin/make /usr/bin/gmake
            ;;
        alpine)
            run $sudo apk update
            run $sudo apk add cmake make pkgconf g++ linux-headers libarchive-tools
    esac
}

unset IFS

unset sudo

[ "$(id -u)" -eq 0 ] || sudo=sudo

__setup_${2%%-*}

[ -f cacert.pem ] && run export SSL_CERT_FILE="$PWD/cacert.pem"

case $2 in
    openbsd-7.[0-4]-amd64)
        PKG=
        ;;
    *)  PKG=python3
esac

XXXXXX="uctags-build-tools-$1-$2"
PREFIX="/opt/$XXXXXX"

run $sudo install -d -g `id -g -n` -o `id -u -n` "$PREFIX"

run ./xbuilder install automake libtool pkgconf gmake findutils diffutils $PKG --prefix="$PREFIX"

case $2 in
    linux-glibc-*)
        run cp -L `gcc -print-file-name=libcrypt.so.1` "$PREFIX/lib/"
        LIBPERL_DIR="$(patchelf --print-rpath          "$PREFIX/bin/perl")"
        LIBPERL_PATH="$LIBPERL_DIR/libperl.so"
        run chmod +w "$LIBPERL_PATH"
        run patchelf --set-rpath "$PREFIX/lib" "$LIBPERL_PATH"
esac

run bsdtar cvaPf "$XXXXXX.tar.xz" "$PREFIX"
