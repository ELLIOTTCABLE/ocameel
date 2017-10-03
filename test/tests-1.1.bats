#!/usr/bin/env bats

# vim: set expandtab sw=3 sts=3 tabstop=3 list listchars=tab:\ ⎯
# ----
# This file contains hard-tabs. Intentionally. (Thanks, Bash.)
#
# Vim will have defaulted to ‘expanding’ tabs to spaces, when you hit <Tab>; but when inside a
# PROGRAM heredoc, below, `:set noet` can be used to disable that behaviour, and insert hard-tabs as
# required — alternatively, <Ctrl-V><Tab> will *always* insert a single hard-tab.

load test-helper


@test "exists" {
   ocameel
}

@test "integers: 0" {
   cat <<-PROGRAM >program.scm
		0
	PROGRAM
   run ocameel program.scm

   [ "$status" -eq 0 ]
   [ "$output" = "0" ]
}
