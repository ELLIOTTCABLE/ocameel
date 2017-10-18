#!/usr/bin/env bats

# vim: set expandtab sw=3 sts=3 tabstop=3 listchars=tab\:\ ⎯ list:
# ----
# This file contains hard-tabs. Intentionally. (Thanks, Bash.)
#
# Vim will have defaulted to ‘expanding’ tabs to spaces, when you hit <Tab>; but when inside a
# PROGRAM heredoc, below, `:set noet` can be used to disable that behaviour, and insert hard-tabs as
# required — alternatively, <Ctrl-V><Tab> will *always* insert a single hard-tab.

load test-helper

assert command -v ocameel >/dev/null


@test "immediate constants: #f" {
   executable="$(tempfile)"
   ocameel -o "$executable" - <<-PROGRAM
		#f
	PROGRAM

   run "$executable"
   [ "$status" -eq 0 ]
   [ "$output" = "#f" ]
}
