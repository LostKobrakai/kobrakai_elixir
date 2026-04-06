defmodule Kobrakai.OIDC.Provider do
  def child_spec(_) do
    Oidcc.ProviderConfiguration.Worker.child_spec(%{
      name: __MODULE__,
      issuer: Application.fetch_env!(:kobrakai, __MODULE__)[:issuer]
    })
  end
end
