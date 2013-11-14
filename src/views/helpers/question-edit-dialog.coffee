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
$ = (require "debug") "R20:helpers:story-edit-dialog"

module.exports = renderable (options) ->
  $ "%j", arguments
  $ "%j", options

  div
    class   : "modal fade"
    id      : options?.title or "question-edit-dialog"
    tabindex: -1
    role    : "dialog"
    =>
      div class: "modal-dialog", =>
        div class: "modal-content", =>
          
          div class: "modal-header", =>
            button
              type  : "button"
              class :"close"
              data:
                dismiss: "modal"
              aria:
                hidden: true
              -> i class: "icon-remove"
            h4 "What's the legal question?"
          
          div class: "modal-body", =>
            if options?.method is "PUT"
              p "Doesn't suit your legal taste? Please make adjustments as you see fit."
            else
              p "You are about to add a new legal question. Are you sure it's not already there?"


            form
              method: "post"
              action: options?.action
              =>
                @helper "csrf"
                div class: "form-group", =>
                  div class: "input-group", =>
                    label for: "text", class: "sr-only", "Question text:"
                    input
                      type        : "text"
                      name        : "text"
                      class       : "form-control"
                      placeholder : "Enter the text of a question..."
                    div class: "input-group-btn", =>
                      button
                        type        : "submit"
                        class       : "btn btn-primary"
                        "ok"
