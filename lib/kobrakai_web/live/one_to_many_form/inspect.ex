defimpl Inspect, for: KobrakaiWeb.OneToManyForm.GroceriesList do
  def inspect(form, opts) do
    [_, _ | rest] = Module.split(form.__struct__)

    Inspect.Map.inspect(
      form,
      rest |> Module.concat() |> Kernel.inspect(),
      form |> Map.drop([:__struct__]) |> Map.keys() |> Enum.map(&%{field: &1}),
      opts
    )
  end
end

defimpl Inspect, for: KobrakaiWeb.OneToManyForm.GroceriesList.Line do
  def inspect(form, opts) do
    [_, _ | rest] = Module.split(form.__struct__)

    Inspect.Map.inspect(
      form,
      rest |> Module.concat() |> Kernel.inspect(),
      form |> Map.drop([:__struct__, :delete]) |> Map.keys() |> Enum.map(&%{field: &1}),
      opts
    )
  end
end
