{
  renderable, tag, text
  div, span
  h3, h4, p
  a, i
} = require "teacup"
_ = require "underscore"
_.string  = require "underscore.string"

module.exports = renderable ->
  h3 class: "text-muted", "What are we up to lately?"
  div class: "list-group", =>
    for story in @stories
      a href: "/story/#{story._id}", class: "list-group-item", =>
        h4
          class: "list-group-item-heading"
          "There is a new story."
        p
          class: "list-group-item-text"
          _.string.prune story.text, 64
      
    a href: "/story/", class: "list-group-item active", =>
      h4 class: "list-group-item-heading", ->
        i class: "icon-star"
        text " Tell us your stroy."
      p class: "list-group-item-text", "Share your story with us. We will try to help."
