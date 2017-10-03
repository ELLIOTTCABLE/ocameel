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


@test "accepts: filename" {
   program="$(tempfile)"
   cat <<-PROGRAM >"$program.scm"
		(test foo bar)
	PROGRAM
   run ocameel "$program.scm"

   [ "$status" -eq 0 ]
   [ "$output" = "(test foo bar)" ]
}

@test "accepts: standard-input" {
   run ocameel <<-PROGRAM
		(test foo bar)
	PROGRAM

   [ "$status" -eq 0 ]
   [ "$output" = "(test foo bar)" ]
}

@test "parsing: integer" {
   run ocameel - <<-PROGRAM
		0
	PROGRAM

   [ "$status" -eq 0 ]
   [ "$output" = "0" ]
}

@test "parsing: s-exp" {
   run ocameel - <<-PROGRAM
		(test foo bar)
	PROGRAM

   [ "$status" -eq 0 ]
   [ "$output" = "(test foo bar)" ]
}

@test "parsing: multiple s-exps" {
   run ocameel - <<-PROGRAM
		(test foo bar)
		(test2 baz widget)
	PROGRAM

   [ "$status" -eq 0 ]
   [ "${lines[0]}" = "(test foo bar)" ]
   [ "${lines[1]}" = "(test2 baz widget)" ]
}

@test "parsing: a real program" {
   run ocameel - <<-PROGRAM
		(import (list-tools setops) (more-setops) (rnrs))
		(define-syntax pr
		  (syntax-rules ()
		    [(_ obj)
		     (begin
		       (write 'obj)
		       (display " ;=> ")
		       (write obj)
		       (newline))]))
		(define get-set1
		  (lambda ()
		    (quoted-set a b c d)))
		(define set1 (get-set1))
		(define set2 (quoted-set a c e))

		(pr (list set1 set2))
		(pr (eq? (get-set1) (get-set1)))
		(pr (eq? (get-set1) (set 'a 'b 'c 'd)))
		(pr (union set1 set2))
		(pr (intersection set1 set2))
		(pr (difference set1 set2))
		(pr (set-cons 'a set2))
		(pr (set-cons 'b set2))
		(pr (set-remove 'a set2))
	PROGRAM

   [ "$status" -eq 0 ]
   [ "${lines[0]}" = "(import (list-tools setops) (more-setops) (rnrs))" ]
}
