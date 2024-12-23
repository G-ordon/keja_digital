defmodule KejaDigital.Store.User do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(
    full_name
    postal_address
    phone_number
    nationality
    organization
    next_of_kin
    next_of_kin_contact
    passport
    door_number
  )a

  @optional_fields ~w(photo)a


  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :role, :string, default: "Tenant"

    field :full_name, :string
    field :postal_address, :string
    field :phone_number, :string
    field :nationality, :string
    field :organization, :string
    field :next_of_kin, :string
    field :next_of_kin_contact, :string
    field :photo, :string
    field :passport, :string
    field :door_number, :string

    timestamps(type: :utc_datetime)
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
    |> cast(attrs, [:email, :password, :role] ++ @required_fields ++ @optional_fields)
    |> validate_length(:full_name, min: 10, max: 30)
    |> validate_format(:full_name, ~r/^[A-Z][a-z]+\s[A-Za-z]+\s?[A-Za-z]*$/, message: "must start with a capital letter and contain 2 or 3 names")
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_required(@required_fields)
    |> validate_phone_number(:phone_number)
    |> validate_format(:phone_number, ~r/^07\d{8}$|^\+254\d{9}$/, message: "Phone number must start with 07 or +254 and follow the correct format")
    |> validate_format(:next_of_kin_contact, ~r/^07\d{8}$|^\+254\d{9}$/, message: "Next of kin contact must start with 07 or +254 and follow the correct format")
    |> validate_length(:passport, min: 6, message: "Your passport number is too short")
    |> unique_constraint(:email)
    |> unique_constraint(:phone_number)
    |> unique_constraint(:full_name)
    |> put_change(:role, "tenant")
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_format(:email, ~r/^[a-zA-Z0-9._%+-]+@(gmail\.com|yahoo\.com)$/, message: "must be a valid email from Gmail or Yahoo")
    |> maybe_validate_unique_email(opts)
  end

  # Custom validation for phone number (Kenyan Safaricom)
  defp validate_phone_number(changeset, field) do
    phone_number = get_field(changeset, field)

    # Ensure the phone number is not nil and matches the Safaricom number format
    case phone_number do
      nil ->
        add_error(changeset, field, "Phone number cannot be blank")

      _ ->
        # Ensure it starts with +254 or 07, and is 10 digits long (after the country code)
        case Regex.match?(~r/^(?:\+254|07)\d{8}$/, phone_number) do
          true -> changeset
          false -> add_error(changeset, field, "must be a valid Safaricom phone number")
        end
    end
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
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
      |> unsafe_validate_unique(:email, KejaDigital.Repo)
      |> unique_constraint(:email)
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
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
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
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%KejaDigital.Store.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
