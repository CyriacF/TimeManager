defmodule TimeManagerWeb.Router do
  use TimeManagerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end
  pipeline :authenticated do
    plug TimeManagerWeb.Plugs.AuthPipeline
  end

  scope "/auth", TimeManagerWeb do
    pipe_through :api  # Applique le pipeline de base API (sans authentification)
    post "/register", AuthController, :register  # Route pour l'enregistrement d'utilisateur
    post "/login", AuthController, :login        # Route pour la connexion et obtenir le JWT
  end


  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :time_manager, swagger_file: "swagger.json"
  end


  scope "/api", TimeManagerWeb do
    pipe_through [:api, :authenticated]

    post "/logout", AuthController, :logout      # Route pour la déconnexion (invalidation du token)
    put "/change_password", AuthController, :change_password

    # Routes for Users
    resources "/users", UserController, except: [:new, :edit]
    resources "/tasks", TaskController, except: [:new, :edit]
    resources "/teams", TeamController, except: [:new, :edit]

#route du user connecter
    get "/me", UserController, :get_me    # Route pour obtenir les infos de l'utilisateur connecté
    put "/me", UserController, :update_me # Route pour mettre à jour les infos de l'utilisateur connecté
    get "/myclock", ClockController, :index_me
    post "/myclock", ClockController, :create_me
    # Routes for Tasks (ajoutez ces lignes)

    get "/users/:user_id/tasks", TaskController, :index
    get "/tasks/:user_id/:id", TaskController, :show

    post "/users/:id/photo", UserController, :upload_photo
    get "/users/:id/photo", UserController, :get_photo

    post "/tasks/:user_id", TaskController, :create
    put "/tasks/:id", TaskController, :update
    delete "/tasks/:user_id/:id", TaskController, :delete


    # Routes for WorkingTime
    get "/workingtime/:user_id", WorkingTimeController, :index
    get "/workingtime/:user_id/:id", WorkingTimeController, :show
    post "/workingtime/:user_id", WorkingTimeController, :create
    put "/workingtime/:id", WorkingTimeController, :update
    delete "/workingtime/:id", WorkingTimeController, :delete

    # Routes for Clocks

    get "/clocks/:user_id", ClockController, :index

    post "/clocks/:user_id", ClockController, :create
    post "/clocks_with_state", ClockController, :create_with_state
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:time_manager, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: TimeManagerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # Définition Swagger principale
  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "Gotham T.M API",
        description: "API pour l'application Gotham Time Manager",
        contact: %{
          name: "Gotham Corporation",
          email: "",
          url: "https://www.gothamcorp.com"
        }
      },
      basePath: "/api",
      schemes: ["http", "https"],
      consumes: ["application/json"],
      produces: ["application/json"],
      securityDefinitions: %{
        BearerAuth: %{
          type: "apiKey",
          name: "Authorization",
          in: "header",
          description: "JWT Authorization header using the Bearer scheme. Example: 'Bearer {token}'"
        }
      }
    }
  end



end
