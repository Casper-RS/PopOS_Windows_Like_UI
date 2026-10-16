#!/bin/sh
# Build the Windows-like lock screen: COSMIC's cosmic-greeter with
# cosmic-greeter-lockscreen.patch applied.
#
#   lockscreen/build.sh          build with the host toolchain (cargo, libpam0g-dev,
#                                libclang-dev, libxkbcommon-dev, libudev-dev, libinput-dev)
#   lockscreen/build.sh --sdk    build inside the Flatpak SDK (installs what it needs, no root)
#
# Prints the path of the built binary on the last line.
set -eu

# Matches the cosmic-greeter shipped with Pop!_OS COSMIC 1.10.
REV=98df07df93df1cb091c95451f7162dca1a2ae2dd
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${LOCKSCREEN_BUILD_DIR:-$HOME/.cache/windows-like-ui-lockscreen}
SRC=$WORK/cosmic-greeter
mkdir -p "$WORK"

# Source at the pinned commit. The repo keeps its images in Git LFS; skip
# that and fetch the one image the build embeds.
if [ ! -d "$SRC/.git" ]; then
    GIT_LFS_SKIP_SMUDGE=1 git -c filter.lfs.process= -c filter.lfs.smudge=cat \
        -c filter.lfs.required=false clone -q https://github.com/pop-os/cosmic-greeter "$SRC"
fi
git -C "$SRC" config filter.lfs.process ""
git -C "$SRC" config filter.lfs.smudge cat
git -C "$SRC" config filter.lfs.clean cat
git -C "$SRC" config filter.lfs.required false
git -C "$SRC" checkout -qf "$REV"
git -C "$SRC" clean -qfd src
git -C "$SRC" apply "$HERE/cosmic-greeter-lockscreen.patch"
curl -fsSL -o "$SRC/res/background.jpg" \
    "https://media.githubusercontent.com/media/pop-os/cosmic-greeter/$REV/res/background.jpg"

if [ "${1:-}" != "--sdk" ]; then
    (cd "$SRC" && cargo build --release --locked --bin cosmic-greeter >&2)
    echo "$SRC/target/release/cosmic-greeter"
    exit 0
fi

# Flatpak SDK build. pam-sys needs libclang (LLVM extension) and the PAM
# headers, which the SDK lacks: take those from Ubuntu's libpam0g-dev and
# link against the host's libpam.
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y --noninteractive flathub org.freedesktop.Sdk//25.08 \
    org.freedesktop.Sdk.Extension.rust-stable//25.08 org.freedesktop.Sdk.Extension.llvm21//25.08 >&2
PAM=$WORK/pam
if [ ! -f "$PAM/root/usr/include/security/pam_appl.h" ]; then
    mkdir -p "$PAM/lib"
    (cd "$PAM" && apt-get download libpam0g-dev >&2 && dpkg-deb -x libpam0g-dev_*.deb root)
    for lib in libpam libpam_misc; do
        cp -L "/usr/lib/x86_64-linux-gnu/$lib.so.0" "$PAM/lib/"
        ln -sf "$lib.so.0" "$PAM/lib/$lib.so"
    done
fi
# The SDK has no libinput; it isn't used, so an empty stub satisfies the linker.
if [ ! -f "$WORK/stub/libinput.so" ]; then
    mkdir -p "$WORK/stub"
    flatpak run --filesystem="$WORK" --command=sh org.freedesktop.Sdk//25.08 -c \
        "echo | cc -shared -x c - -o '$WORK/stub/libinput.so'"
fi
flatpak run --share=network --filesystem="$WORK" --command=sh org.freedesktop.Sdk//25.08 -c "
    export PATH=/usr/lib/sdk/rust-stable/bin:/usr/lib/sdk/llvm21/bin:\$PATH CARGO_HOME='$WORK/cargo'
    export LIBCLANG_PATH=/usr/lib/sdk/llvm21/lib
    export BINDGEN_EXTRA_CLANG_ARGS='-I$PAM/root/usr/include'
    export RUSTFLAGS='-L $PAM/lib -L $WORK/stub'
    cd '$SRC' && cargo build --release --locked --bin cosmic-greeter" >&2
echo "$SRC/target/release/cosmic-greeter"
