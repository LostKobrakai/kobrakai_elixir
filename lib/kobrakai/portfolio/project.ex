defmodule Kobrakai.Portfolio.Project do
  @enforce_keys [
    :id,
    :title,
    :draft,
    :body,
    :date,
    :tags,
    :primary,
    :secondary,
    :headline,
    :subtitle
  ]
  defstruct [:id, :title, :draft, :body, :date, :tags, :primary, :secondary, :headline, :subtitle]

  def parse(_path, contents) do
    ["---\n" <> yaml, body] = :binary.split(contents, ["\n---\n"])
    {:ok, attrs} = YamlElixir.read_from_string(yaml)
    attrs = Map.new(attrs, fn {k, v} -> {String.to_atom(k), v} end)
    {attrs, body}
  end

  def build(filename, attrs, body) do
    [year, month, day, id] = filename |> Path.basename(".md") |> String.split("-", parts: 4)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")

    %__MODULE__{
      id: id,
      title: attrs.title,
      date: date,
      body: body,
      draft: !!attrs[:draft],
      tags: Map.get(attrs, :tags, []),
      primary: Map.fetch!(attrs, :primary),
      secondary: Map.fetch!(attrs, :secondary),
      headline: Map.get(attrs, :headline),
      subtitle: Map.get(attrs, :subtitle)
    }
  end
end
