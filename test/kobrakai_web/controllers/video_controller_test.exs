defmodule KobrakaiWeb.VideoControllerTest do
  use KobrakaiWeb.ConnCase

  describe "GET /video" do
    test "works", %{conn: conn} do
      Req.Test.stub(Kobrakai.Bold, fn conn ->
        Req.Test.json(conn, %{data: [%{id: "12345", published_at: "2024-11-05T10:00:00"}]})
      end)

      conn = get(conn, ~p"/video")

      assert html = html_response(conn, 200)

      assert html =~ ~p"/video/12345"
    end
  end
end
