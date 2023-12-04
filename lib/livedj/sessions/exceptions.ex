defmodule Livedj.Sessions.Exceptions do
  @moduledoc false
  defmodule PlayerServerError do
    @moduledoc false
    use Livedj.Exception
  end

  defmodule PlaylistServerError do
    @moduledoc false
    use Livedj.Exception
  end

  defmodule SessionRoomError do
    @moduledoc false
    use Livedj.Exception
  end
end
