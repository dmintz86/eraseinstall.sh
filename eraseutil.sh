#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Copyright (c) 2018 Jamf.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the Jamf nor the names of its contributors may be
#                 used to endorse or promote products derived from this software without
#                 specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

################################################################################################
# Information to be aware of
#. This script is tested to work with High Sierra and Mojave		
#  You must set $4 variable as the api username and $5 as the api password
#	
#	You should also use the $6 variable for the JSS url. 
#
################################################################################################


#Variables used in the Jamf helper portion of this script
iconpath="/Library/build/"
icon="logo.PNG"
heading1="Erase and Install."
description1="Please wait while we update your machine details and begin the erase and install."

#this is the location that the pashua.sh lives in.
MYDIR="/private/tmp/pashua/"

# Include pashua.sh to be able to use the 2 functions defined in that file
source "$MYDIR/pashua.sh"

#This sectio defines what the utility looks like. 

conf="
# Set window title
*.title = Welcome to erase and install.

# Introductory text
txt.type = text
txt.default = Welcome to the erase and install utility. This utility helps you prepare your mac for an erase and install of macOS. Please choose from the following options to initiate the process.[return][return] Once you have made your choice and selected go, it will take approximatly 15 minutes to begin the process.Once the process has begun you will not be able to use the mac. 
txt.height = 276
txt.width = 310
txt.x = 400
txt.y = 150
txt.tooltip = This is an element of type “text”

# Add a text field
tf1.type = textfield
tf1.label = Machine Name to be used after erase and install
tf1.default = Please use format initials-mac-pretendco
tf1.width = 310
tf1.tooltip = This is an element of type “textfield”

# Add a text field
tf.type = textfield
tf.label = New users windows username
tf.default = username goes here
tf.width = 310
tf.tooltip = This is an element of type “textfield”

# Add a text field
tf2.type = textfield
tf2.label = New users full name
tf2.default = full name goes here
tf2.width = 310
tf2.tooltip = This is an element of type “textfield”

# Add a text field
tf3.type = textfield
tf3.label = New users email
tf3.default = email goes here
tf3.width = 310
tf3.tooltip = This is an element of type “textfield”


# Define radiobuttons
rb.type = radiobutton
rb.label = Please choose the new users department.
rb.option = Administration
rb.option = Design
rb.option = IT Services
rb.option = Marketing
rb.tooltip = This is an element of type “radiobutton”

# Add a popup menu
pop.type = popup
pop.label = Please choose the build type for this machine. 
pop.width = 310
pop.option = New starter basic
pop.option = New starter advanced
pop.option = IT test machine
pop.default = New starter basic
pop.tooltip = This is an element of type “popup”

# Add 2 checkboxes
chk.rely = -18
chk.type = checkbox
chk.label = Please check this box to confim you are happy to erase and install this mac.
chk.tooltip = This is an element of type “checkbox”
chk.default = 0
#chk2.type = checkbox
#chk2.label = But this one is disabled
#chk2.disabled = 1
#chk2.tooltip = Another element of type “checkbox”

# Add a cancel button with default label
cb.type = cancelbutton
cb.tooltip = This is an element of type “cancelbutton”

db.type = defaultbutton
db.tooltip = This is an element of type “defaultbutton” (which is automatically added to each window, if not included in the configuration)
"

if [ -d '/Volumes/Pashua/Pashua.app' ]
then
	# Looks like the Pashua disk image is mounted. Run from there.
	customLocation='/Applications/Pashua'
else
	# Search for Pashua in the standard locations
	customLocation=''
fi

# Get the icon from the application bundle
locate_pashua "$customLocation"
bundlecontents=$(dirname $(dirname "$pashuapath"))
if [ -e "$bundlecontents/Resources/AppIcon@2.png" ]
then
    conf="$conf
          img.type = image
          img.x = 435
          img.y = 295
          img.maxwidth = 128
          img.tooltip = This is an element of type “image”
          img.path = $bundlecontents/Resources/AppIcon@2.png"
fi

pashua_run "$conf" "$customLocation"

echo "Pashua created the following variables:"
echo "  tb  = $tb"
echo "  tf  = $tf"
echo "  tf1  = $tf1"
echo "  tf2  = $tf2"
echo "  ob  = $ob"
echo "  pop = $pop"
echo "  rb  = $rb"
echo "  cb  = $cb"
echo "  chk = $chk"
echo ""
 



#Lock the screen to begin the software install.

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType fs -icon "$iconpath$icon" -iconsize 2000 -heading "$heading1" -description "$description1" &


serial=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')

# Create xml
    cat << EOF > /private/tmp/ea.xml
<computer>
    <extension_attributes>
        <extension_attribute>
            <name>Build</name>
            <value>$pop</value>
        </extension_attribute>
    </extension_attributes>
</computer>
EOF

# Create xml
    cat << EOF > /private/tmp/ea1.xml
<computer>
    <extension_attributes>
        <extension_attribute>
            <name>newmacname</name>
            <value>$tf1</value>
        </extension_attribute>
    </extension_attributes>
</computer>
EOF

## Upload the xml file
curl -sfku $4:$5 $6/JSSResource/computers/serialnumber/${serial} -T /private/tmp/ea.xml -X PUT
curl -sfku $4:$5 $6/JSSResource/computers/serialnumber/${serial} -T /private/tmp/ea1.xml -X PUT


jamf recon -endUsername $tf
jamf recon -realname $tf2
jamf recon -email $tf3
jamf recon -department $rb
jamf setcomputername -name $tf1
jamf recon

#This custom policy trigger kicks off the erase and install script. 
jamf policy -trigger erase

#kill jamf helper

/usr/local/bin/jamf killJAMFHelper

jamf policy -trigger starterase


