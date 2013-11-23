{
  renderable, tag, text
  div, span
  h3, h4, p
  a, i, small
}         = require "teacup"
_         = require "underscore"
_.string  = require "underscore.string"
moment    = require "moment"

module.exports = renderable ->
  h4 "What are we up to lately?"
  div class: "list-group", =>
    for entry in @entries
      switch entry.action
        when "draft"
          switch entry.model 
            when "Story"
              a href: "/story/#{entry.data._id}/draft/#{entry._id}", class: "list-group-item", =>
                h4 class: "list-group-item-heading", =>
                  i class: "icon-file-text", " "
                  text "#{entry.meta.author} wrote a draft for a story."
                p
                  class: "list-group-item-text"
                  _.string.prune entry.data.text, 64
                p => small class: "pull-right", moment(entry._id.getTimestamp()).fromNow()
        
        when "apply"
          draft = entry.data._draft
          switch entry.model
            when "Story"
              a href: "/story/#{draft.data._id}", class: "list-group-item", =>
                h4 class: "list-group-item-heading", =>
                  i class: "icon-ok-sign", " "
                  text "#{entry.meta.author} applied " + (
                    if draft.meta.author is entry.meta.author then "his own draft "
                    else " a draft by #{draft.meta.author}"
                  ) + "to a story."
                p
                  class: "list-group-item-text"
                  _.string.prune draft.data.text, 64
                p => small class: "pull-right", moment(entry._id.getTimestamp()).fromNow()
      
        when "remove"
          document = entry.data
          switch entry.model
            when "Story"
              a href: "/story/#{document._id}", class: "list-group-item", =>
                h4 class: "list-group-item-heading", =>
                  i class: "icon-remove-sign", " "
                  text "#{entry.meta.author} removed a story."
                p
                  class: "list-group-item-text"
                  _.string.prune document.text, 64
                p => small class: "pull-right", moment(entry._id.getTimestamp()).fromNow()
        
    a 
      href: "#!new-story"
      class: "list-group-item active"
      data:
        toggle: "modal"
        target: "#story-edit-dialog"
      =>
        h4 class: "list-group-item-heading", ->
          i class: "icon-star"
          text " Tell us your stroy."
        p class: "list-group-item-text", "Share your story with us. We will try to help."

  @helper "story-edit-dialog", action: "/story/"
