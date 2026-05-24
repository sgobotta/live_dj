defmodule LivedjWeb.Layouts do
  @moduledoc false

  use LivedjWeb, :html

  import LivedjWeb.SessionModals

  embed_templates "layouts/*"
end
