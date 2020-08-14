# Bash script to simplistically obfuscate API key

GOOGLE_KEY_PATH="Keys/GoogleAPI.key"
SPEECH_KEY_PATH="Keys/GreynirSpeechAPI.key"

GOBF=""
SOBF=""

if [ ! -e $GOOGLE_KEY_PATH ]; then
    echo "DummyKey" > $GOOGLE_KEY_PATH
fi

if [ ! -e $SPEECH_KEY_PATH ]; then
    echo "DummyKey" > $SPEECH_KEY_PATH
fi

GOBF=`base64 -i ${GOOGLE_KEY_PATH}`
SOBF=`base64 -i ${SPEECH_KEY_PATH}`

cat << EOF
const char *gak = "${GOBF}";
const char *sak = "${SOBF}";
EOF

