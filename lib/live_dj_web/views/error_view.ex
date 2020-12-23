defmodule LiveDjWeb.ErrorView do
  use LiveDjWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  def render("500.html", assigns) do
    render("internal_server_error.html", assigns)
  end

  def render("404.html", assigns) do
    render("not_found.html", assigns)
  end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
