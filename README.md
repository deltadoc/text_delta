# TextDelta

Elixir counter-part for the Quill.js [Delta](https://github.com/quilljs/delta)
library. It provides a baseline for [Operational
Transformation](https://en.wikipedia.org/wiki/Operational_transformation) of
rich text.

More information on original Delta format can be found
[here](https://quilljs.com/docs/delta/). The best starting point for learning
Operational Transformation is likely [this
article](http://www.codecommit.com/blog/java/understanding-and-applying-operational-transformation).

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
