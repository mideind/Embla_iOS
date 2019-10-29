# Bash script to simplistically obfuscate API key

KEY_PATH="Embla/Keys/GoogleAPI.key"
OBF=""

if [ ! -e $KEY_PATH ]; then
    echo "DummyKey" > $KEY_PATH
fi

OBF=`base64 -i ${KEY_PATH}`

cat << EOF
const char *gak = "${OBF}";
EOF


