defmodule Kobrakai.Blog.Post do
  @enforce_keys [:id, :title, :draft, :body, :date]
  defstruct [:id, :title, :draft, :body, :date]

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
      draft: !!attrs[:draft]
    }
  end
end
