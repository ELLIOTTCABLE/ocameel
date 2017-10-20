load '../node_modules/bats-support/load'
load '../node_modules/bats-assert/load'

puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}

pathadd() {
   if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
      PATH="$1${PATH:+":$PATH"}"                ; fi ;}

absolute() {
   (cd "$(dirname "$1")" &>/dev/null && printf "%s/%s" "$PWD" "${1##*/}") ;}

pathadd "$(absolute './_build/install/default/bin')"

contains() { [ -z "${1##*$2*}" ] && [ -z "$2" -o -n "$1" ] ;}

tempfile() { mktemp    "$BATS_TMPDIR/${BATS_TEST_NAME}.XXXX" ;}
tempdir()  { mktemp -d "$BATS_TMPDIR/${BATS_TEST_NAME}.XXXX" ;}


# ### Ocameel-specific
compile-and-exec() {
   exec 3<&0
   executable="$(tempfile)"

   ocameel - <&3 -o "$executable"
   exec 3<&-

   "$executable" "$@"
}
