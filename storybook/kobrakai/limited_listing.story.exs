defmodule Storybook.Kobrakai.LimitedListing do
  use PhoenixStorybook.Story, :component

  def function, do: &KobrakaiWeb.Components.limited_listing/1
  def imports, do: [{KobrakaiWeb.CoreComponents, button: 1}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          list: Enum.to_list(1..15),
          max: 9
        },
        let: :limited,
        slots: [
          """
          <ul>
            <li :for={i <- limited}>
              <%= i %>
            </li>
          </ul>
          """,
          """
          <:link :let={length}>
            <.button>Got up to <%= length %></.button>
          </:link>
          """
        ]
      },
      %Variation{
        id: :reverse,
        attributes: %{
          list: Enum.to_list(1..15),
          max: 9,
          reverse: true
        },
        let: :limited,
        slots: [
          """
          <ul>
            <li :for={i <- limited}>
              <%= i %>
            </li>
          </ul>
          """,
          """
          <:link :let={length}>
            <.button>Got up to <%= length %></.button>
          </:link>
          """
        ]
      },
      %Variation{
        id: :reverse_from_bottom,
        attributes: %{
          list: Enum.to_list(1..15),
          max: -9,
          reverse: true
        },
        let: :limited,
        slots: [
          """
          <ul>
            <li :for={i <- limited}>
              <%= i %>
            </li>
          </ul>
          """,
          """
          <:link :let={length}>
            <.button>Got up to <%= length %></.button>
          </:link>
          """
        ]
      },
      %Variation{
        id: :not_truncated,
        attributes: %{
          list: Enum.to_list(1..2),
          max: 4
        },
        let: :limited,
        slots: [
          """
          <ul>
            <li :for={i <- limited}>
              <%= i %>
            </li>
          </ul>
          """,
          """
          <:link :let={length}>
            <.button>Got up to <%= length %></.button>
          </:link>
          """
        ]
      }
    ]
  end
end
