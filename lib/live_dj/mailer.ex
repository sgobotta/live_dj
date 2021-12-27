defmodule LiveDj.Mailer do
  @moduledoc false

  use Bamboo.Mailer, otp_app: :live_dj
end

defmodule LiveDj.Email do
  @moduledoc false

  import Bamboo.Email

  def new(to, body, subject) do
    new_email(
      to: to,
      from: "noreplylivedj@gmail.com",
      subject: subject,
      text_body: body
    )
  end
end
