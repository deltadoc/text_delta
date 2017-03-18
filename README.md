# TextDelta

[![Build Status](https://travis-ci.org/everzet/text_delta.svg?branch=master)](https://travis-ci.org/everzet/text_delta)

Elixir counter-part for the Quill.js [Delta](https://github.com/quilljs/delta)
library. It provides a baseline for [Operational
Transformation](https://en.wikipedia.org/wiki/Operational_transformation) of
rich text.

More information on original Delta format can be found
[here](https://quilljs.com/docs/delta/). The best starting point for learning
Operational Transformation is likely [this
article](http://www.codecommit.com/blog/java/understanding-and-applying-operational-transformation).

## Acknowledments

This library is heavily influenced by two other libraries and wouldn't be
possible without them:

1. [`quilljs/delta`](https://github.com/quilljs/delta) - original JS library
   entire public API of `text_delta` is based upod. `text_delta` was created to
   provide a server counter-part to frontend Delta's.
2. [`jclem/ot_ex`](https://github.com/jclem/ot_ex) - implementation of this
   library is heavily influenced by `ot_ex` and though this library pursues
   slightly different avenue of OT, it wouldn't be possible without it.

## Differences with `ot_ex`

If you are searching for a library matching Quill's Delta format, but on the
server side, this library is pretty much a direct match. If, however, you're
looking for a more general Operational Transformation library, you should
consider both this library and its alternative - `ot_ex`. Here are key
differences from `ot_ex` that might help you make the decision:

1. `text_delta` is heavily based on Quill Delta, including the public API and
   the delta format itself. This results in a more verbose format than what
   `ot_ex` uses.
2. `ot_ex` uses fully reversible operations format, while `text_delta` is a
   one-way. If reversibility is a must, `ot_ex` is a better option.
3. `text_delta` allows arbitrary attributes to be attached to `insert` or
   `retain` operations. This would allow you to transform rich text alongside
   plain. With `ot_ex` you pretty much stuck with plain text format, which might
   not be a big deal if your format of choice is something like Markdown.
4. `ot_ex` has RNG-backed test suite, which covers many more cases and,
   potentially, has less bugs. `text_delta` uses more traditional example-based
   tests similar to Quill Delta itself. I believe this provides adequeted
   coverage, but nothing beats RNG :)

## Installation

TextDelta can be installed by adding `text_delta` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:text_delta, "~> 1.0.0"}]
end
```

## Documentation

Documentation can be found at [https://hexdocs.pm/text_delta](https://hexdocs.pm/text_delta).

## Testing & Linting

This library is test-driven. In order to run tests, execute:

```bash
$> mix test
```

The library also uses [Credo](http://credo-ci.org) and
[Dialyzer](http://erlang.org/doc/man/dialyzer.html). To run both, execute:

```bash
$> mix lint
```
