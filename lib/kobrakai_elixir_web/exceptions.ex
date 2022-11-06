defimpl Plug.Exception, for: Kobrakai.Blog.NotFoundError do
  def status(_), do: 404
  def actions(_), do: []
end
