defmodule Kobrakai.ReverseProxyPlug.FinchClient do
  @moduledoc false
  alias ReverseProxyPlug.HTTPClient

  @behaviour HTTPClient

  @impl true
  def request(%HTTPClient.Request{} = request) do
    case request.options[:stream_to] do
      nil -> sync_request(request)
      pid when is_pid(pid) -> async_request(request, pid)
    end
  end

  defp async_request(%HTTPClient.Request{} = request, _pid) do
    finch_request =
      Finch.build(
        request.method,
        request.url
        |> URI.new!()
        |> URI.append_query(URI.encode_query(request.query_params)),
        private_headers(request.headers),
        request.body,
        request.options
      )

    task =
      Task.async(fn ->
        Finch.stream(
          finch_request,
          Kobrakai.Finch,
          [],
          fn
            {:status, _status}, acc -> acc
            {:headers, _headers}, acc -> acc
            {:data, _data}, acc -> acc
          end,
          request.options
        )
      end)

    {:ok, %HTTPClient.AsyncResponse{id: task.ref}}
  end

  defp sync_request(%HTTPClient.Request{} = request) do
    Finch.build(
      request.method,
      request.url
      |> URI.new!()
      |> URI.append_query(URI.encode_query(request.query_params)),
      private_headers(request.headers),
      request.body,
      request.options
    )
    |> Finch.request(Kobrakai.Finch)
    |> case do
      {:ok, %Finch.Response{} = response} ->
        {:ok,
         %HTTPClient.Response{
           status_code: response.status,
           body: response.body,
           headers: response.headers,
           request: request,
           request_url: request.url
         }}

      {:error, err} ->
        {:error,
         %HTTPClient.Error{
           id: nil,
           reason: err
         }}
    end
  end

  defp private_headers(headers) do
    List.keydelete(headers, "cookie", 0)
  end
end
