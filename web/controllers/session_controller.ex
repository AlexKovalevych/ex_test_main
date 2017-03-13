defmodule Gt.SessionController do
  @moduledoc """
  Provides login and logout for the admin part of the site.
  """
  use Gt.Web, :controller
  alias Gt.User
  require Logger

  @server "Globotunes"

  plug Ueberauth, providers: [:identity]

  # Make sure that we have a valid token in the session
  # We've aliased Gt.Plug.EnsureAuthenticated in our Gt.Web.controller macro
  plug EnsureAuthenticated, [handler: __MODULE__] when action in [:logout, :locale]

  def locale(conn, %{"locale" => locale} = params, user) do
    if locale in Application.get_env(:gt, :locales) do
      user
      |> User.changeset(params)
      |> Repo.update!
      conn |> redirect(to: NavigationHistory.last_path(conn, 1, default: dashboard_path(conn, :index)))
    end
  end

  def new(conn, _params, _user) do
    render conn, "new.html", current_user: nil
  end

  def callback(%Plug.Conn{assigns: %{ueberauth_failure: fails}} = conn, _params, user) do
    conn
    |> put_flash(:error, hd(fails.errors).message)
    |> render("new.html", current_user: user)
  end

  # In this function, when sign in is successful we sign_in the user into the :default section
  # of the Guardian session
  def callback(%Plug.Conn{assigns: %{ueberauth_auth: auth}} = conn, _params, _current_user) do
    case User.from_auth(auth) do
      {:ok, user} ->
        conn = conn |> Guardian.Plug.sign_in(user)
        case user.auth do
          "none" -> conn
                    |> put_session(:two_factor, true)
                    |> redirect(to: redirect_back(conn))
          "sms" -> auth = User.update_sms(user)
                   |> Repo.update!
                   send_sms(user, auth)
                   conn
                   |> render("sms.html", current_user: nil, phone: Gt.ViewHelpers.phone(user.phone))
          "google" ->
            case User.provider_auth(user, :google) do
              {:ok, authorization} ->
                conn
                |> render("google.html", current_user: nil, qrcode_url: google_qrcode_url(user, authorization))
              _ ->
                Logger.error("User #{user.email} doesn't have google auth")
                to_login(conn, gettext("internal_error"), :error)
            end
        end
      {:error, reason} ->

        conn
        |> put_flash(:error, reason)
        |> render("new.html", current_user: nil)
    end
  end

  def sms_resend(conn, _, current_user) do
    auth = User.update_sms(current_user) |> Repo.update!
    with :ok <- send_sms(current_user, auth) do
          conn |> send_resp(200, Poison.encode!(""))
    else
      _ -> conn |> send_resp(500, Poison.encode!(""))
    end
  end

  def sms(conn, %{"code" => code}, current_user) do
    current_user = Repo.preload(current_user, [:authorizations])
    if User.check_failed_limit(current_user) do
      to_login(conn, dgettext("login", "user_disabled"), :error)
    else
      case User.provider_auth(current_user, :sms) do
        {:ok, auth} ->
          if auth.token == code do
            User.login(current_user) |> Repo.update!
            conn
            |> put_session(:two_factor, true)
            |> redirect(to: redirect_back(conn))
          else
            User.login_failed(current_user) |> Repo.update!
            conn
            |> put_flash(:error, dgettext("login", "invalid_code"))
            |> render("sms.html", current_user: nil, phone: Gt.ViewHelpers.phone(current_user.phone))
          end
        {:error, _} ->
          Logger.error("No sms provider for #{current_user.email}")
          to_login(conn, gettext("internal_error"), :error)
      end
    end
  end

  def google(conn, %{"code" => code}, current_user) do
    current_user = Repo.preload(current_user, [:authorizations])
    if User.check_failed_limit(current_user) do
      to_login(conn, dgettext("login", "user_disabled"), :error)
    else
      with {:ok, authorization} <- User.provider_auth(current_user, :google),
           {true, _} <- {:pot.valid_totp(code, authorization.token), authorization} do
            User.login(current_user) |> Repo.update!
            User.set_show_img(current_user, false) |> Repo.update!
            conn
            |> put_session(:two_factor, true)
            |> redirect(to: redirect_back(conn))
      else
        {:error, :no_provider} ->
          Logger.error("No google provider for #{current_user.email}")
          to_login(conn, gettext("internal_error"), :error)
        {false, authorization} ->
          User.login_failed(current_user) |> Repo.update!
          conn
          |> put_flash(:error, dgettext("login", "invalid_code"))
          |> render("google.html", current_user: nil, qrcode_url: google_qrcode_url(current_user, authorization))
      end
    end
  end

  def logout(conn, _params, _current_user) do
    conn = Guardian.Plug.sign_out(conn)
    to_login(conn)
  end

  def unauthenticated(conn, %{reason: {:error, reason}}) do
    reason = case reason do
      :token_not_found -> dgettext("login", "not_authenticated")
      _ -> reason
    end
    if reason != :no_session, do: to_login(conn, reason, :error), else: to_login(conn)
  end

  defp google_qrcode_url(user, auth) do
    if auth.show_img do
      "https://chart.googleapis.com/chart?cht=qr&chs=200x200&chl=" <>
      URI.encode_www_form("otpauth://totp/#{@server}:#{user.email}?secret=#{auth.token}")
    end
  end

  defp redirect_back(conn) do
    NavigationHistory.last_path(conn, default: dashboard_path(conn, :index))
  end

  defp to_login(conn) do
    conn |> redirect(to: login_path(conn, :new))
  end

  defp to_login(conn, reason, :error) do
    conn |> put_flash(:error, reason) |> to_login
  end

  defp to_login(conn, info, :info) do
    conn |> put_flash(:info, info) |> to_login
  end

  defp send_sms(user, auth) do
    try do
      GenServer.call(:gt_amqp_default, {:send, :iqsms, Poison.encode!(%Gt.Amqp.Messages.Sms{
                       phone: user.phone,
                       clientId: :os.system_time(:seconds),
                       text: auth.token
                     })})
    catch
      :exit, _ ->
        Logger.error("Can't send SMS")
        :error
    end
  end

end
