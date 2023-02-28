defmodule Storybook.Kobrakai.BrandHeader do
  use PhoenixStorybook.Story, :component

  def function, do: &KobrakaiWeb.Components.brand_header/1
  def container, do: :iframe

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          back: false
        }
      },
      %Variation{
        id: :back,
        attributes: %{
          back: false
        }
      }
    ]
  end
end
