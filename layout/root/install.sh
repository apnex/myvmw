#!/bin/bash
# myvmw BASH installation script

# uninstall any existing client
REGEX='([^:]+)'
STRING=$PATH
INPATH=0
while [[ $STRING =~ $REGEX ]]; do
	STRING=${STRING#*"${BASH_REMATCH[1]}"}
	TESTDIR="${BASH_REMATCH[1]}/myvmw"
	if [[ -f $TESTDIR ]]; then
		echo "Uninstalling existing myvmw [$TESTDIR]"
		rm "$TESTDIR"
	fi
done

echo "Installing myvmw CLI client"
read -p "username: " USERNAME
# add in syntax checking for email
printf "password: "
PASSWORD=''
# output asterisks for each character pressed
while IFS= read -r -s -n1 char; do
	[[ -z $char ]] && { printf '\n'; break; }
	if [[ $char == $'\x7f' ]]; then
		[[ -n $PASSWORD ]] && PASSWORD=${PASSWORD%?}
		printf '\b \b'
	else
		PASSWORD+=$char
		printf '*'
	fi
done



# need to add a check for relative or absolute (user inputs leading /)
DEFAULT="${HOME}/vmwfiles"
read -p "Enter download directory or press <enter> for default [$DEFAULT]: " WORKING
if [[ -n $WORKING ]]; then
	DIR=$WORKING
else
	DIR=$DEFAULT
fi
if [[ ! -d $DIR ]]; then
	echo "Creating new dir[$DIR]"
	mkdir $DIR
else
	echo "Using existing dir[$DIR]"
fi

echo "Writing [$DIR/config.json]"
# add obfuscation of password
read -r -d '' CONFIG <<CONFIG
{
	"username": "$USERNAME",
	"password": "$PASSWORD"
}
CONFIG
echo "$CONFIG" > ${DIR}/config.json

# Parse PATH and select last dir
BINDIR="${HOME}/bin"
read -p "Enter BIN directory to install myvmw or press <enter> for default [$BINDIR]: " UBIN
if [[ -n $UBIN ]]; then
	BINDIR=$UBIN
fi
if [[ ! -d $BINDIR ]]; then
	echo "Creating dir[$BINDIR]"
	mkdir $BINDIR
else
	echo "BIN dir[$BINDIR] exists!"
fi

# add a touch check for permissions
# check if zsh exist
PROFILE="${HOME}/.zshrc"
if [[ ! -f $PROFILE ]]; then
	PROFILE="${HOME}/.bashrc"
fi
echo "SHELL RC file detected[$PROFILE]"
read -r -d '' BASHSTRING <<EOF
export PATH=\$PATH:$BINDIR
EOF
REGEX='([^:]+)'
STRING=$PATH
INPATH=0
while [[ $STRING =~ $REGEX ]]; do
	STRING=${STRING#*"${BASH_REMATCH[1]}"}
	TESTPATH="${BASH_REMATCH[1]}"
	if [[ $TESTPATH == $BINDIR ]]; then
		echo "BIN dir[$BINDIR] already in PATH!"
		echo "PATH=$PATH"
		INPATH=1
	fi
done
if [[ "$INPATH" == "0" ]]; then
	echo "Adding [$BINDIR] to PATH in [$PROFILE]"
	echo "$BASHSTRING" >> ${PROFILE}
fi

echo "Installing [$BINDIR/myvmw]"
read -r -d '' MYVMW <<MYVMW
#!/bin/bash
docker run --net host -v $DIR:/vmwfiles apnex/myvmw "\$1" "\$2"
MYVMW
echo "$MYVMW" > ${BINDIR}/myvmw
chmod 755 ${BINDIR}/myvmw
echo "Done! - please run command [source $PROFILE] to activate current shell, or open a new terminal"
