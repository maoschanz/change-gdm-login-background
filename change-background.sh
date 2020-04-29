#!/bin/bash

## Add personal background to gdm3 login screen
## Tested with Ubuntu 20.04
##
## Needs the following package : libglib2.0-dev-bin

if [ ! $(command -v glib-compile-resources) ]; then
	echo "The following package must be installed to continue: libglib2.0-dev-bin"
	echo
	echo "You can run the following command in a terminal:"
	echo "sudo apt install libglib2.0-dev-bin";
	exit 1
fi

################################################################################
# Constants ####################################################################

GST=/usr/share/gnome-shell/gnome-shell-theme.gresource

BACKGROUND_TARGET_NAME=noise-texture.png
BACKGROUND_WIDTH=1366
BACKGROUND_HEIGHT=768

ORIGINAL_BACKGROUND="#lockDialogGroup {\n  background-color: #41494c; }"
EDITED_BACKGROUND="#lockDialogGroup {\n  background: #41494c url(file:///usr/share/gnome-shell/theme/${BACKGROUND_TARGET_NAME});\n  background-size: ${BACKGROUND_WIDTH}px ${BACKGROUND_HEIGHT}px;\n  background-repeat: none;\n}"

################################################################################
# Functions ####################################################################

function extract_current_theme {
	# If not present, create 'theme' directory
	if test ! -d theme; then
		mkdir -p theme
	fi # XXX else quoi ?

	# Extract resources
	for r in `gresource list $GST`; do
		gresource extract $GST $r 2>/dev/null >${r#\/org\/gnome\/shell/}
	done
}

function edit_css_content {
	if test -f theme/gdm3.css; then
		css_file=gdm3.css
	elif test -f theme/gnome-shell.css; then
		css_file=gnome-shell.css
	else
		echo "No css file found!"
		exit 1
	fi

	sed -i -z "s%${ORIGINAL_BACKGROUND}%${EDITED_BACKGROUND}%" "theme/${css_file}"
	# Apply customization to the .css file
}

function create_new_gresource {
	echo "Writing a new version of gnome-shell-theme.gresource.xml..."

	# Write a new "gnome-shell-theme.gresource.xml" file
	FILES=$(find "theme" -type f -printf "%P\n" | xargs -i echo "    <file>{}</file>")
	cat <<EOF >"theme/gnome-shell-theme.gresource.xml"
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/org/gnome/shell/theme">
${FILES}
  </gresource>
</gresources>
EOF

	# Compile this XML file into a new gresource file
	echo "Compiling gnome-shell-theme.gresource..."
	cd theme
	glib-compile-resources gnome-shell-theme.gresource.xml && \
	echo "The file 'gnome-shell-theme.gresource' has been successfully created!"
	cd ..
}

function install_new_theme {
	# Copy your picture renamed 'noise-texture.png' to /usr/share/gnome-shell/theme
	echo "Copy your picture as 'noise-texture.png' to /usr/share/gnome-shell/theme"
	sudo cp "$1" /usr/share/gnome-shell/theme/${BACKGROUND_TARGET_NAME} && echo "Done !"

	# Copy the custom 'gnome-shell-theme.gresource' to /usr/share/gnome-shell
	echo "Copy the custom 'gnome-shell-theme.gresource' to /usr/share/gnome-shell/theme"
	sudo cp theme/gnome-shell-theme.gresource /usr/share/gnome-shell && echo "Done !"
}

################################################################################
# "Main" part of the script ####################################################

background_source_name=$1

# TODO s'assurer quil y a bien un $1

extract_current_theme

if test -f ${background_source_name}; then
	cp -vf ${background_source_name} theme/${BACKGROUND_TARGET_NAME}
	# TODO confirmer que c'est un PNG
else
	printf '%s\n' "'${background_source_name}' file not found!"
	exit 1
fi

edit_css_content

create_new_gresource

echo
echo "####################################################"
echo "# The next operations require superuser privileges #"
echo "####################################################"

# Save a backup of the original 'gnome-shell-theme.gresource'
echo "Saving original 'gnome-shell-theme.gresource' to 'gnome-shell-theme.gresource.backup'"
if test -f $GST; then
	sudo cp $GST{,.backup}
	echo "Done !" # FIXME sans doute idiot. Ramener un backup daté dans pwd
fi

install_new_theme "${background_source_name}"

# Make new gnome-shell-theme.gresource as default alternative
echo "Make new CSS the new default alternative"
sudo update-alternatives --set gdm3-theme.gresource $GST >/dev/null && echo "Done !"

echo
echo "Restart your computer and enjoy :)"
echo "(you can delete the directory '${PWD}/theme')"

################################################################################

