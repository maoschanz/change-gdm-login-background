#!/bin/bash

## Add personal wallpaper to gdm3 login screen
## Tested with Ubuntu 20.04
##
## Needs the following package : libglib2.0-dev-bin

if [ ! $(command -v glib-compile-resources) ]; then
	printf '%s\n' "The following package must be installed to continue: libglib2.0-dev-bin
You can run the following command to a terminal:
sudo apt install libglib2.0-dev-bin";
	exit 1
fi

workdir=${PWD}
wallpaper=noise-texture.png # Place your picture in ${wordir} and rename it to 'noise-texture.png'
gst=/usr/share/gnome-shell/gnome-shell-theme.gresource
css=gdm3.css
original_part="#lockDialogGroup {\n  background-color: #41494c; }"
modified_part="#lockDialogGroup {\n  background: #41494c url(file:///usr/share/gnome-shell/theme/${wallpaper});\n  background-size: 1920 px 1080 px;\n  background-repeat: none; }"

# If not present, create 'theme' directory
if test ! -d ${workdir}/theme; then
	mkdir -p ${workdir}/theme
fi

# Copying Yaru-dark theme to 'theme' directory
if test -d /usr/share/themes/Yaru-dark; then
	cp /usr/share/themes/Yaru-dark/gnome-shell/* ${workdir}/theme/
else
	printf '%s\n' "No Yaru-dark directory found!
Maybe your operating system is not Ubuntu?";
	exit 1
fi

# gdm3 picture file 'noise-texture.png' must be found in ${workdir} directory
if test -f ${workdir}/${wallpaper}; then
	cp -vf ${workdir}/${wallpaper} ${workdir}/theme/${wallpaper}
else
	printf '%s\n' "'${wallpaper}' file not found!"; exit 1
fi

# Extract resources
for r in `gresource list $gst`; do
	gresource extract $gst $r 2>/dev/null >$workdir/${r#\/org\/gnome\/shell/}
done

# Apply customization to 'gdm3.css' file
sed -i -z "s%${original_part}%${modified_part}%" "${workdir}/theme/${css}"

# Write a new "gnome-shell-theme.gresource.xml" file
FILES=$(find "theme" -type f -printf "%P\n" | xargs -i echo "    <file>{}</file>")
cat <<EOF >"${workdir}/theme/gnome-shell-theme.gresource.xml"
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/org/gnome/shell/theme">
${FILES}
  </gresource>
</gresources>
EOF

# Compile this XML file into a new gresource file
printf '%s\n' "Compile gnome-shell-theme.gresource"
cd ${workdir}/theme
glib-compile-resources gnome-shell-theme.gresource.xml && \
printf '%s\n' "The file 'gnome-shell-theme.gresource' has been successfully created!


"

################################################################################

printf '%s\n' "#####
### The next operations require superuser privileges
#####

"

# Save a backup of the original 'gnome-shell-theme.gresource'
printf '%s\n' "Saving original 'gnome-shell-theme.gresource' to 'gnome-shell-theme.gresource.backup'"
if test -f /usr/share/gnome-shell/gnome-shell-theme.gresource; then
	sudo cp /usr/share/gnome-shell/gnome-shell-theme.gresource{,.backup}
	printf '%s\n' "Done !

"
fi

# Copy your picture renamed 'noise-texture.png' to /usr/share/gnome-shell/theme
printf '%s\n' "Copy your picture as 'noise-texture.png' to /usr/share/gnome-shell/theme"
sudo cp ${wallpaper} /usr/share/gnome-shell/theme && printf '%s\n' "Done !

"

# Copy the custom 'gnome-shell-theme.gresource' to /usr/share/gnome-shell
printf '%s\n' "Copy the custom 'gnome-shell-theme.gresource' to /usr/share/gnome-shell/theme"
sudo cp ${workdir}/theme/gnome-shell-theme.gresource /usr/share/gnome-shell && printf '%s\n' "Done !

"

# Make new gnome-shell-theme.gresource as default alternative
printf '%s\n' "Make new gdm3.css the new default alternative"
sudo update-alternatives --set gdm3-theme.gresource /usr/share/gnome-shell/gnome-shell-theme.gresource >/dev/null && printf '%s\n' "Done !

"

# End operations
printf '%s\n' "Restart your computer and enjoy :)"


