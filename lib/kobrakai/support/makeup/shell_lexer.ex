defmodule Kobrakai.Makeup.ShellLexer do
  # Source: https://github.com/elixir-lang/ex_doc/blob/main/lib/ex_doc/shell_lexer.ex
  #
  # License
  #
  # Copyright 2012 Plataformatec
  # Copyright 2021 The Elixir Team
  # https://github.com/elixir-lang/ex_doc/
  #
  #   Licensed under the Apache License, Version 2.0 (the "License");
  #   you may not use this file except in compliance with the License.
  #   You may obtain a copy of the License at
  #
  #       http://www.apache.org/licenses/LICENSE-2.0
  #
  #   Unless required by applicable law or agreed to in writing, software
  #   distributed under the License is distributed on an "AS IS" BASIS,
  #   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  #   See the License for the specific language governing permissions and
  #   limitations under the License.
  #
  # Makeup lexer for sh, bash, etc commands.
  # The only thing it does is making the `$ ` prompt not selectable.
  @moduledoc false

  @behaviour Makeup.Lexer

  def register() do
    Makeup.Registry.register_lexer(__MODULE__,
      options: [],
      names: ["shell", "console", "sh", "bash", "zsh"],
      extensions: []
    )
  end

  @impl true
  def lex(text, _opts) do
    text
    |> String.split("\n")
    |> Enum.flat_map(fn
      "$ " <> rest ->
        [
          {:generic_prompt, %{selectable: false}, "$ "},
          {:text, %{}, rest <> "\n"}
        ]

      text ->
        [{:text, %{}, text <> "\n"}]
    end)
  end

  @impl true
  def match_groups(_arg0, _arg1) do
    raise "not implemented yet"
  end

  @impl true
  def postprocess(_arg0, _arg1) do
    raise "not implemented yet"
  end

  @impl true
  def root(_arg0) do
    raise "not implemented yet"
  end

  @impl true
  def root_element(_arg0) do
    raise "not implemented yet"
  end
end
