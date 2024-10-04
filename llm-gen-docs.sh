#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LOGFILE=$(mktemp /tmp/docs_update.XXXXXX.log)

echo "Logging to $LOGFILE"
inputs=$(
  cd $2
  echo PATCH:
  cat $1
  echo
  echo EXISTING DOCUMENTATION:
  files-to-prompt docs/ || exit 1
)
echo Generating Docs
suggestion=$(
  node "$SCRIPT_DIR/gemini.js" "$SCRIPT_DIR/generate-docs.yaml" <<< "$inputs"
)
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Suggestion:" >> "$LOGFILE"
echo "$suggestion" >> "$LOGFILE"

inputs=$(
  cd $2
  echo EXISTING DOCUMENTATION:
  files-to-prompt docs/ || exit 1
  echo
  echo SUGGESTED CHANGES:
  echo "$suggestion"
)
echo Generating Update
newdocs=$(
  node "$SCRIPT_DIR/gemini.js" "$SCRIPT_DIR/update-docs.yaml" <<< "$inputs"
)
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Update:" >> "$LOGFILE"
echo "$newdocs" >> "$LOGFILE"

echo Writing Update
node "$SCRIPT_DIR/write-files.js" <<< "$newdocs" || exit 1
