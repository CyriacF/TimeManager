defmodule TimeManagerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :time_manager

  # Les options de session
  @session_options [
    store: :cookie,
    key: "_time_manager_key",
    signing_salt: "LpBSg25D",
    same_site: "Lax"
  ]

  # Configuration du socket LiveView
  socket "/live", Phoenix.LiveView.Socket,
         websocket: [connect_info: [session: @session_options]],
         longpoll: [connect_info: [session: @session_options]]

  # Servir les fichiers statiques
  plug Plug.Static,
       at: "/",
       from: :time_manager,
       gzip: false,
       only: TimeManagerWeb.static_paths()

  # Rechargement de code
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :time_manager
  end

  # Plug pour le CORS
  plug CORSPlug, origin: ["http://localhost", "http://localhost:5173", "http://15.188.55.199"]

  # Autres plugs
  plug Phoenix.LiveDashboard.RequestLogger,
       param_key: "request_logger",
       cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
       parsers: [:urlencoded, :multipart, :json],
       pass: ["*/*"],
       json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug TimeManagerWeb.Router
end