{
  renderable, tag, text, raw
  div, main, aside, nav
  table, th, tr, td
  ul, li
  h3, h4, p
  i, span, strong
  a
  form, button, input, textarea, label
  hr, br
  coffeescript
}         = require "teacup"
moment    = require "moment"
_         = require "underscore"
debug     = require "debug"

$         = debug "R20:helpers:story-drafts-dialog"

module.exports = renderable (options) ->

  div
    # TODO: DRY - universal draft list for stories, questions, answers and profiles
    class   : "modal fade"
    id      : "drafts-dialog"
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
            h4 "Drafts of this #{options.type}"
          
          div class: "modal-body", =>
             table class: "table table-hover table-condensed table-striped", =>
              tr =>
                th => span class: "sr-only", "state"
                th "author"
                th "time"

              for draft in ( _(@journal).filter (entry) -> entry.action is "draft" )
                applied = chosen = no
                if options?.type? and @[options.type]._draft?
                  applied  = @[options.type]._draft.equals draft._id

                chosen   = @draft?._id?.equals   draft._id

                if      chosen  then  icon = "circle"
                else if applied then  icon = "ok-circle" 
                else                  icon = "circle-blank"
                
                time    = moment(draft._id.getTimestamp()).fromNow()
                author  = draft.meta.author

                tr class: (if chosen then "active" else if applied then "success"), =>

                  td =>
                    i class: "icon-li icon-" + icon
                    span class: "sr-only", if chosen then "chosen" else if applied then "applied"

                  td =>
                    if not applied then a
                      href: "/#{options.type}/#{@[options.type]._id}/draft/#{draft._id}"
                      author.name
                    else strong author.name

                  td =>
                    if not applied then a
                      href: "/#{options.type}/#{@[options.type]._id}/draft/#{draft._id}"
                      time
                    else strong time
