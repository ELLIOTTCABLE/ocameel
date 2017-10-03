#!/usr/bin/env bats

# vim: set expandtab sw=3 sts=3 tabstop=3 list listchars=tab:\ ⎯
# ----
# This file contains hard-tabs. Intentionally. (Thanks, Bash.)
#
# Vim will have defaulted to ‘expanding’ tabs to spaces, when you hit <Tab>; but when inside a
# PROGRAM heredoc, below, `:set noet` can be used to disable that behaviour, and insert hard-tabs as
# required — alternatively, <Ctrl-V><Tab> will *always* insert a single hard-tab.

load test-helper

assert command -v ocameel >/dev/null


@test "integers: 0" {
   run ocameel <<-PROGRAM
		0
	PROGRAM

   [ "$status" -eq 0 ]
   [ "$output" = "0" ]
}
