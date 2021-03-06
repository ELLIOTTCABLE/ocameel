A Bajillion Toy Schemes
=======================
At [StrangeLoop][] (well, really, [PWLconf][]) 2017, [James Long][] [introduced][talk] me to
Abdulaziz Ghuloum's [An Incremental Approach to Compiler Construction][paper], an
academic-whitepaper-formatted compiler-writing tutorial.

At the same time, I was refreshing my ML knowledge, picking up OCaml — and I thought it'd be fun,
perhaps, to take a stab at following the IACC, but in ML instead of Scheme.

So, someday (probably not-so-soon), this repository may contain a (shitty) (slow) (pointless)
(partial) implementation of Scheme in OCaml. ([As if there aren't][1] [enough of those already.][2]
🙄)

(Note: The `tests` were originally written by Professor Ghuloum, retreived from Wayback Machine for
this URL: <http://www.cs.indiana.edu/~aghuloum/compilers-tutorial-tests-2006-10-11.tgz>. I do not
have any copyright over, or claim on, them.)

   [StrangeLoop]: <https://thestrangeloop.com/> "StrangeLoop Conference, St. Louis, MO"
   [PWLConf]: <https://pwlconf.org> "Papers We Love Conf, St. Louis, MO"
   [James Long]: <https://twitter.com/jlongster> "James Long (@jlongster) on Twitter"
   [talk]: <https://pwlconf.org/2017/james-long/>
      "“My History with Papers”, a talk by James Long, at StrangeLoop 2017"
   [paper]: <http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf>
      "“An Incremental Approach to Compiler Construction”, Abdulaziz Ghuloum, SFP'06"

   [1]: <https://github.com/tadruj/SCHEMana-ocaml>
   [2]: <https://github.com/dvanhorn/ubik>


“Usage”
-------
This is useless. But hey.

    brew install opam && \
       opam init && \
       eval `opam config env`

    opam install core jbuilder

    npm run-script prepare

    ./_build/install/default/bin/ocameel --help
    ./_build/install/default/bin/ocameel -o - -S - <<<"42"

    ./_build/install/default/bin/ocameel -o answer.s -S - <<<"42"
    gcc -c src/runtime.c
    gcc -o answer ./omg.o ./runtime.o
    ./answer

(Yes. It literally only compiles the number ‘42.’ Told you it was useless.)

Of note, I've only tested this on macOS — there's some `system` calls that almost certainly need to
be re-written for a Linux. Should only be a minor effort.
