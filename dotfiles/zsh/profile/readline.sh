# Readline

if [ -z "$INPUTRC" ]; then
  if [ -f "$HOME/.inputrc" ]; then
    export INPUTRC="$HOME/.inputrc"
  else
    if [ -f "/etc/inputrc" ]; then
      export INPUTRC="/etc/inputrc"
    fi
  fi
fi
