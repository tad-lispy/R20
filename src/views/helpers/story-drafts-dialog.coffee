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
moment    = require "moment"
debug     = require "debug"
$         = debug "R20:helpers:story-drafts-dialog"

module.exports = renderable (options) ->
  div
      class   : "modal fade"
      id      : "story-drafts-dialog"
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
                => i class: "icon-remove"
              h4 "Drafts of this story."
            
            div class: "modal-body", =>
              ul class: "icons-ul", =>
                for draft in @drafts
                  li =>
                    if (@story._draft?.equals   draft._id) and 
                      not @story.isNew                     then icon = "ok-circle" 
                    else if @draft?._id?.equals draft._id  then icon = "circle"
                    else                                        icon = "circle-blank"

                    i class: "icon-li icon-" + icon
                    a href: "/story/#{@story._id}/draft/#{draft._id}", =>
                      text moment(draft._id.getTimestamp()).fromNow()
                      text " by " + draft.meta.author



              # form
              #   method: "post"
              #   action: options?.action
              #   =>
              #     @helper "csrf"
              #     if options?.method?
              #       input type: "hidden", name: "_method", value: options.method
              #     div class: "form-group", =>
              #       label for: "text", "What's the story?", class: "sr-only"
              #       textarea
              #         name        : "text"
              #         class       : "form-control"
              #         rows        : 8
              #         style       : "resize: none"
              #         placeholder : "Give us the facts, we will give you the law..."
              #         @story?.text

              #     div class: "form-group", =>
              #       button
              #         type        : "submit"
              #         class       : "btn btn-primary"
              #         =>
              #           i class: "icon-check-sign"
              #           text " Ok"
