defmodule Kobrakai.Blog.Post do
  @enforce_keys [:id, :title, :headline, :draft, :excerpt, :body, :date, :tags]
  defstruct [:id, :title, :headline, :draft, :excerpt, :body, :date, :tags]

  def parse(_path, contents) do
    ["---\n" <> yaml, body] = :binary.split(contents, ["\n---\n"])
    {:ok, attrs} = YamlElixir.read_from_string(yaml)
    attrs = Map.new(attrs, fn {k, v} -> {String.to_atom(k), v} end)

    attrs =
      case :binary.split(body, ["\n<!-- excerpt -->\n"]) do
        [excerpt | [_ | _]] -> Map.put(attrs, :excerpt, String.trim(excerpt))
        _ -> attrs
      end

    {attrs, body}
  end

  def build(filename, attrs, body) do
    [year, month, day, id] = filename |> Path.basename(".md") |> String.split("-", parts: 4)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")

    %__MODULE__{
      id: id,
      headline: Map.get(attrs, :headline),
      title: attrs.title,
      date: date,
      excerpt: attrs[:excerpt],
      body: body,
      draft: !!attrs[:draft],
      tags: Map.get(attrs, :tags, [])
    }
  end
end
