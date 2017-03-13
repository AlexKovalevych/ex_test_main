defmodule Gt.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    if error = form.errors[field] do
      content_tag :div, translate_error(error), class: "form-control-feedback"
    end
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, [count: count] = opts}) do
    # Because error messages were defined within Ecto, we must
    # call the Gettext module passing our Gettext backend. We
    # also use the "errors" domain as translations are placed
    # in the errors.po file. On your own code and templates,
    # this could be written simply as:
    #
    #     dngettext "errors", "1 file", "%{count} files", count
    #
    Gettext.dngettext(Gt.Gettext, "errors", msg, msg, count, opts)
  end

  def translate_error({msg, _}) do
    translate_error(msg)
  end

  def translate_error(msg) do
    Gettext.dgettext(Gt.Gettext, "errors", msg)
  end
end
