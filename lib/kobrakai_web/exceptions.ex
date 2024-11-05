defimpl Plug.Exception, for: Kobrakai.Blog.NotFoundError do
  def status(_), do: 404
  def actions(_), do: []
end

defimpl Plug.Exception, for: Kobrakai.Bold.NotFoundError do
  def status(_), do: 404
  def actions(_), do: []
end
