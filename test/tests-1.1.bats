#!/usr/bin/env bats

load test-helper

assert command -v ocameel >/dev/null

compile-and-exec() {
   exec 3<&0
   executable="$(tempfile)"

   ocameel - <&3 -o "$executable"
   exec 3<&-

   "$executable" "$@"
}


@test "integers: 0" {
   run compile-and-exec <<<"0"

   [ "$status" -eq 0 ]
   [ "$output" = "0" ]
}

@test "integers: 1" {
   run compile-and-exec <<<"1"

   [ "$status" -eq 0 ]
   [ "$output" = "1" ]
}

@test "integers: -1" {
   run compile-and-exec <<<"-1"

   [ "$status" -eq 0 ]
   [ "$output" = "-1" ]
}

@test "integers: 10" {
   run compile-and-exec <<<"10"

   [ "$status" -eq 0 ]
   [ "$output" = "10" ]
}

@test "integers: -10" {
   run compile-and-exec <<<"-10"

   [ "$status" -eq 0 ]
   [ "$output" = "-10" ]
}

@test "integers: 2736" {
   run compile-and-exec <<<"2736"

   [ "$status" -eq 0 ]
   [ "$output" = "2736" ]
}

@test "integers: -2736" {
   run compile-and-exec <<<"-2736"

   [ "$status" -eq 0 ]
   [ "$output" = "-2736" ]
}

@test "integers: 536870911" {
   run compile-and-exec <<<"536870911"

   [ "$status" -eq 0 ]
   [ "$output" = "536870911" ]
}

@test "integers: -536870911" {
   run compile-and-exec <<<"-536870911"

   [ "$status" -eq 0 ]
   [ "$output" = "-536870911" ]
}
