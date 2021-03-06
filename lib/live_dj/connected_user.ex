defmodule LiveDj.ConnectedUser do
  defstruct uuid: "", username: ""

  alias LiveDj.ConnectedUser

  def create_connected_user(username) do
    uuid = UUID.uuid4()
    %ConnectedUser{uuid: uuid, username: username}
  end
end
