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
marked    = require "marked"
debug     = require "debug"

marked.setOptions
  breaks      : true
  sanitize    : true
  smartypants : true

$         = debug "R20:helpers:story-drop-dialog"

module.exports = renderable (options) ->
  div
      class   : "modal fade"
      id      : "story-drop-dialog"
      tabindex: -1
      role    : "dialog"
      =>
        div class: "modal-dialog", =>
          div class: "modal-content", =>
            
            div
              class: "modal-header"
              style: """                
                background: hsl(2, 65%, 58%);
                border-top-right-radius: 3px;
                border-top-left-radius: 3px;
              """ # TODO: move to css file
              =>
                button
                  type  : "button"
                  class :"close"
                  data:
                    dismiss: "modal"
                  aria:
                    hidden: true
                  -> i class: "icon-remove"
                h4 "Drop this story?"
            
            div class: "modal-body", =>
              form
                method: "post"
                action: options?.action
                =>
                  @helper "csrf"
                  input type: "hidden", name: "_method", value: "DELETE"
                  p "Do you really want to drop this story?"
                  
                  div class: "well", =>
                    raw marked @story.text
                  
                  p "Dropping a story is roughly equivalent to unpublishing it. It can be undone. All drafts will be preserved."

                  div class: "form-group", =>
                    button
                      type  : "submit"
                      class : "btn btn-danger"
                      =>
                        i class: "icon-remove-sign"
                        text " Ok, drop it!"
