defmodule Mrgr.Slack.Message do
  defmacro __using__(_args) do
    quote do
      use Phoenix.VerifiedRoutes, endpoint: MrgrWeb.Endpoint, router: MrgrWeb.Router
      import MrgrWeb.Formatter

      import unquote(__MODULE__)
    end
  end

  def header(text) do
    %{
      type: "header",
      text: text(text, "plain_text")
    }
  end

  def section(text) do
    %{
      type: "section",
      text: text(text)
    }
  end

  def button(text, url, style \\ "primary") do
    %{
      type: "button",
      text: text(text, "plain_text"),
      style: style,
      url: url
    }
  end

  def text(text, type \\ "mrkdwn") do
    %{type: type, text: text}
  end

  def image(url, alt_text \\ "image") do
    %{
      type: "image",
      image_url: url,
      alt_text: alt_text
    }
  end

  def divider do
    %{
      type: "divider"
    }
  end

  def actions(elements) when is_list(elements) do
    %{
      type: "actions",
      elements: elements
    }
  end

  def actions(element) do
    actions([element])
  end

  def build_link(url, text) do
    "<#{url}|#{text}>"
  end
end
