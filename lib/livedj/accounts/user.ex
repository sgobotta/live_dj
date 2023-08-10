defmodule Livedj.Accounts.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import LivedjWeb.Gettext

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email], message: dgettext("errors", "can't be blank"))
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: dgettext("errors", "must have the @ sign and no spaces")
    )
    |> validate_length(:email,
      max: 160,
      message:
        dngettext(
          "errors",
          "should have at most %{count} caracters(s)",
          "should have at most %{count} caracters(s)",
          16
        )
    )
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password],
      message: dgettext("errors", "can't be blank")
    )
    |> validate_length(:password,
      min: 12,
      max: 72,
      message:
        dgettext("errors", "should be between %{min} and %{max} characters",
          min: 12,
          max: 72
        )
    )
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case
    # character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case
    # character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one
    # digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password,
        max: 72,
        count: :bytes,
        message:
          dgettext("errors", "should be at most %{count} byte(s)", count: 72)
      )
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Livedj.Repo,
        message: dgettext("errors", "has already been taken")
      )
      |> unique_constraint(:email,
        message: dgettext("errors", "has already been taken")
      )
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset ->
        changeset

      %{} = changeset ->
        add_error(changeset, :email, dgettext("errors", "did not change"))
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password,
      message: dgettext("errors", "does not match password")
    )
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(
        %Livedj.Accounts.User{hashed_password: hashed_password},
        password
      )
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_user, _password) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(
        changeset,
        :current_password,
        dgettext("errors", "is not valid")
      )
    end
  end
end
