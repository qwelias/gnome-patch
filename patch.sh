#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o pipefail
set -o nounset
shopt -s globstar
shopt -s nullglob
# set -o xtrace
tab() { sed 's/^/  /'; }
dir=$(dirname "$(readlink -f "$0")")

target=~/.local/share/themes/Monokai
rm -rf $target/*

setup () {
    [ -d gnome-shell ] || (\
        git clone --depth 1 --branch 44.0 https://gitlab.gnome.org/GNOME/gnome-shell.git && \
        git -C gnome-shell apply ../gnome-shell.patch
    )
    [ -d gtk ] || (\
        git clone --depth 1 --branch gtk-3-24 https://gitlab.gnome.org/GNOME/gtk.git && \
        git -C gtk apply ../gtk.patch
    )
    [ -d libadwaita ] || (\
        git clone --depth 1 --branch 1.3.1 https://gitlab.gnome.org/GNOME/libadwaita.git && \
        git -C libadwaita apply ../libadwaita.patch
    )
}


gnomeshell () {
    mkdir -p $target/gnome-shell
    cd $dir/gnome-shell/data/theme
    rm -rf gnome-shell.css
    sassc -a gnome-shell.scss gnome-shell.css
    cp gnome-shell.css $target/gnome-shell
    gsettings set org.gnome.shell.extensions.user-theme name Adwaita
    gsettings set org.gnome.shell.extensions.user-theme name Monokai
}

gtk3 () {
    mkdir -p $target/gtk-3.0
    cd $dir/gtk/gtk/theme/Adwaita
    ./parse-sass.sh
    cp gtk-contained-dark.css $target/gtk-3.0/gtk.css
    cp gtk-contained-dark.css $target/gtk-3.0/gtk-dark.css
    cp -r assets $target/gtk-3.0
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita
    gsettings set org.gnome.desktop.interface gtk-theme Monokai
}

libadwaita () {
    cd $dir/libadwaita
    meson --prefix /usr . _build
    ninja -C _build
    ninja -C _build install
}

for fn in setup gtk3 gnomeshell libadwaita; do
    echo
    echo $fn
    $fn | tab
done