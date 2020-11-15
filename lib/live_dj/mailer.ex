defmodule LiveDj.Mailer do
  use Bamboo.Mailer, otp_app: :live_dj
end

defmodule LiveDj.Email do
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
