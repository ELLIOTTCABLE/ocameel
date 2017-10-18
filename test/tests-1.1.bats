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


@test "integers: 0" {
   executable="$(tempfile)"
   ocameel -o "$executable" - <<-PROGRAM
		0
	PROGRAM

   run "$executable"
   [ "$status" -eq 0 ]
   [ "$output" = "0" ]
}

@test "integers: 1" {
   executable="$(tempfile)"
   ocameel -o "$executable" - <<-PROGRAM
		1
	PROGRAM

   run "$executable"
   [ "$status" -eq 0 ]
   [ "$output" = "1" ]
}

@test "integers: -1" {
   executable="$(tempfile)"
   ocameel -o "$executable" - <<-PROGRAM
		-1
	PROGRAM

   run "$executable"
   [ "$status" -eq 0 ]
   [ "$output" = "-1" ]
}

@test "integers: 10" {
   executable="$(tempfile)"
   ocameel -o "$executable" - <<-PROGRAM
		10
	PROGRAM

   run "$executable"
   [ "$status" -eq 0 ]
   [ "$output" = "10" ]
}

@test "integers: -10" {
   executable="$(tempfile)"
   ocameel -o "$executable" - <<-PROGRAM
		-10
	PROGRAM

   run "$executable"
   [ "$status" -eq 0 ]
   [ "$output" = "-10" ]
}

@test "integers: 2736" {
   executable="$(tempfile)"
   ocameel -o "$executable" - <<-PROGRAM
		2736
	PROGRAM

   run "$executable"
   [ "$status" -eq 0 ]
   [ "$output" = "2736" ]
}

@test "integers: -2736" {
   executable="$(tempfile)"
   ocameel -o "$executable" - <<-PROGRAM
		-2736
	PROGRAM

   run "$executable"
   [ "$status" -eq 0 ]
   [ "$output" = "-2736" ]
}

@test "integers: 536870911" {
   executable="$(tempfile)"
   ocameel -o "$executable" - <<-PROGRAM
		536870911
	PROGRAM

   run "$executable"
   [ "$status" -eq 0 ]
   [ "$output" = "536870911" ]
}

@test "integers: -536870911" {
   executable="$(tempfile)"
   ocameel -o "$executable" - <<-PROGRAM
		-536870911
	PROGRAM

   run "$executable"
   [ "$status" -eq 0 ]
   [ "$output" = "-536870911" ]
}
