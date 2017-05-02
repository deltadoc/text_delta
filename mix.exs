defmodule TextDelta.Mixfile do
  use Mix.Project

  @version "1.1.0"
  @github_url "https://github.com/everzet/text_delta"

  def project do
    [app: :text_delta,
     version: @version,
     description: description(),
     package: package(),
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases(),
     dialyzer: [flags: ~w(-Werror_handling
                          -Wrace_conditions
                          -Wunderspecs
                          -Wunmatched_returns)],
     homepage_url: @github_url,
     source_url: @github_url,
     docs: docs()]
  end

  def application, do: []

  defp aliases do
    [lint: ["credo --strict", "dialyzer --halt-exit-status"]]
  end

  defp description do
    """
    Elixir counter-part for the Quill.js Delta library. It provides a baseline
    for Operational Transformation of rich text.
    """
  end

  defp package do
    [maintainers: ["Konstantin Kudryashov <ever.zet@gmail.com>"],
     licenses: ["MIT"],
     links: %{"GitHub" => @github_url}]
  end

  defp docs do
    [source_ref: "v#{@version}",
     extras: ["README.md": [filename: "README.md", title: "Readme"],
              "CHANGELOG.md": [filename: "CHANGELOG.md", title: "Changelog"],
              "LICENSE.md": [filename: "LICENSE.md", title: "License"]]]
  end

  defp deps do
    [{:ex_doc, "~> 0.15", only: [:dev], runtime: false},
     {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
     {:credo, "~> 0.6", only: [:dev, :test], runtime: false},
     {:eqc_ex, "~> 1.4.2", only: [:dev, :test], runtime: false}]
  end
end
