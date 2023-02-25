defmodule MrgrWeb.Email.Renderer do
  use MrgrWeb, :component

  import MrgrWeb.Components.Email

  embed_templates "../templates/email/*"
end
