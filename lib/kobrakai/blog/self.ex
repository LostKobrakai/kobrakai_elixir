defmodule Kobrakai.Blog.ModuleCode do
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    file = File.read!(env.file)

    quote do
      def module_code() do
        unquote(file)
      end
    end
  end
end
