defmodule TimeManager do
  @moduledoc """
  The entry point for defining your web interface, such as controllers,
  channels, etc.

  This can be used in your application as:

      use TimeManagerWeb, :controller

  The definitions below will be executed for every controller,
  so keep them short and clean, focused on imports,
  uses, and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules and
  import those modules here.
  """

  # Macro pour les contrôleurs
  def controller do
    quote do
      use Phoenix.Controller, namespace: TimeManagerWeb

      import Plug.Conn
      import TimeManagerWeb.Gettext

      alias TimeManagerWeb.Router.Helpers, as: Routes
    end
  end

  # Macro pour le routeur
  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  # Macro pour les canaux (si vous en avez)
  def channel do
    quote do
      use Phoenix.Channel
      import TimeManagerWeb.Gettext
    end
  end

  # Macro nécessaire pour permettre l'utilisation de `use TimeManagerWeb, :controller`
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
