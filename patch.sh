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

setup () {
    [ -d gnome-shell ] || (\
        git clone --depth 1 --branch 45.1 https://gitlab.gnome.org/GNOME/gnome-shell.git gnome-shell && \
        git -C gnome-shell apply ../gnome-shell.patch
    )
    [ -d gtk3 ] || (\
        git clone --depth 1 --branch gtk-3-24 https://gitlab.gnome.org/GNOME/gtk.git gtk3 && \
        git -C gtk3 apply ../gtk.patch
    )
    [ -d libadwaita ] || (\
        git clone --depth 1 --branch 1.4.0 https://gitlab.gnome.org/GNOME/libadwaita.git libadwaita && \
        git -C libadwaita apply ../libadwaita.patch
    )
}

gnomeshell () {
    target=/usr/share/themes/qwelias/gnome-shell/gnome-shell.css
    cd $dir/gnome-shell/data/theme
    rm -rf gnome-shell.css
    sassc -a gnome-shell-dark.scss gnome-shell.css
    sudo mkdir -p $target
    sudo cp gnome-shell.css $target
    gnome-extensions disable gnome-core@qwelias.me
    gnome-extensions enable gnome-core@qwelias.me
}

gtk3 () {
    target=~/.local/share/themes/qwelias
    sudo rm -rf $target/*
    sudo mkdir -p $target/gtk-3.0
    cd $dir/gtk3/gtk/theme/Adwaita
    ./parse-sass.sh
    sudo cp gtk-contained-dark.css $target/gtk-3.0/gtk.css
    sudo cp gtk-contained-dark.css $target/gtk-3.0/gtk-dark.css
    sudo cp -r assets $target/gtk-3.0
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita
    gsettings set org.gnome.desktop.interface gtk-theme qwelias
}

libadwaita () {
    cd $dir/libadwaita
    meson --prefix /usr . _build
    ninja -C _build
    sudo ninja -C _build install
}

clear () {
    rm -rf gnome-shell gtk3 libadwaita
}

if [ $# -eq 0 ]
then args=(setup gtk3 gnomeshell libadwaita)
else args=("$@")
fi

for fn in "${args[@]}"; do
    echo
    echo $fn
    $fn | tab
done
