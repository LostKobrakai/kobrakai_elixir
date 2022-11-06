defimpl Plug.Exception, for: KobrakaiElixir.Blog.NotFoundError do
  def status(_), do: 404
  def actions(_), do: []
end
