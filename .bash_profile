# /etc/skel/.bash_profile

# This file is sourced by bash for login shells.  The following line
# runs your .bashrc and is recommended by the bash info pages.
if [[ -f ~/.bashrc ]] ; then
	. ~/.bashrc


./systemstart
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/ram/.lmstudio/bin"
# End of LM Studio CLI section

