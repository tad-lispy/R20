{
  renderable, tag, text, raw
  div, main, aside, nav
  ul, li
  h3, h4, p
  i, span, strong
  a
  form, button, input, textarea, label
  hr, br
  coffeescript
}         = require "teacup"
_         = require "underscore"
$ = (require "debug") "R20:helpers:story-edit-dialog"

module.exports = renderable (options = {}) ->
  options = _(options).defaults
    document: @story or {}

  div
    class   : "modal fade"
    id      : "story-edit-dialog"
    tabindex: -1
    role    : "dialog"
    =>
      div class: "modal-dialog", =>
        div class: "modal-content", =>
          
          div class: "modal-header", =>
            button
              type  : "button"
              class : "close"
              data:
                dismiss: "modal"
              aria:
                hidden: true
              -> i class: "icon-remove"
            h4 if options.method is "PUT" then "Edit this story." else "Tell us your story."
          
          div class: "modal-body", =>
            form
              method: "post"
              action: options?.action
              =>
                @helper "csrf"
                if options?.method? then input
                  type: "hidden"
                  name: "_method"
                  value: options.method

                div class: "form-group", =>
                  label for: "text", "What's the story?", class: "sr-only"
                  textarea
                    name        : "text"
                    class       : "form-control"
                    rows        : 8
                    style       : "resize: none"
                    placeholder : "Give us the facts, we will give you the law..."
                    options.document.text

                div class: "form-group", =>
                  button
                    type        : "submit"
                    class       : "btn btn-primary"
                    =>
                      i class: "icon-check-sign"
                      text " Ok"
