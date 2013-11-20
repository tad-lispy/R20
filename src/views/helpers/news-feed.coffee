{
  renderable, tag, text
  div, span
  h3, h4, p
  a, i
} = require "teacup"
_ = require "underscore"
_.string  = require "underscore.string"

module.exports = renderable ->
  h4 "What are we up to lately?"
  div class: "list-group", =>
    for entry in @entries
      switch entry.action
        when "draft"
          switch entry.model 
            when "Story"
              a href: "/story/#{entry.data._id}/draft/#{entry._id}", class: "list-group-item", =>
                h4
                  class: "list-group-item-heading"
                  "#{entry.meta.author} wrote a draft for a story."
                p
                  class: "list-group-item-text"
                  _.string.prune entry.data.text, 64
      
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
