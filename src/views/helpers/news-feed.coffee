{
  renderable, render
  tag, text
  div, span, pre
  h3, h4, p
  hr
  a, i, small, strong
}         = require "teacup"
_         = require "underscore"
_.string  = require "underscore.string"
moment    = require "moment"
markdown  = require "./markdown"

debug     = require "debug"

$         = debug "R20:helpers:news_feed"


item      = renderable (options) =>
  options = _.defaults options,
    url   : "#"
    icons : [ "cogs" ]
    class : "default"
    body  : "Something happened."

  a href: options.url, class: "list-group-item", =>
    div class: "media", =>
      
      div class: "pull-left text-" + options.class, =>
        span class: "media-object icon-stack icon-2x", =>
          i class: "icon-stack-base icon-" + options.icons[0]
          i class: "icon-" + options.icons[1] if options.icons[1]?
      
      div class: "media-body", =>
        if typeof options.body is "function" then do options.body
        else p options.body
          
      if options.excerpt? 
        div
          style: """          
            text-overflow: ellipsis;
            white-space: nowrap;
            overflow: hidden;
          """
          => strong _.string.stripTags render => markdown options.excerpt
      
    p class: "text-right", => small moment(options.time).fromNow()

module.exports = renderable ->
  h4 "What are we up to lately?"
  div class: "list-group", =>
    for entry in @entries

      switch entry.model 
        when "Story"

          switch entry.action
            when "draft" then item
              icons   : [ "comment-alt", "edit" ]
              url     : "/story/#{entry.data._id}/draft/#{entry._id}"
              body    : "#{entry.meta.author} wrote a draft for a story."
              excerpt : entry.data.text
              time    : do entry._id.getTimestamp
              class   : "info"
        
            when "apply" 
              draft = entry.data._draft
              item 
                icons   : [ "comment-alt", "check" ]
                url     : "/story/#{draft.data._id}/"
                body    : ->
                  whose = if draft.meta.author is entry.meta.author
                    "his own draft"
                  else
                    " a draft by #{draft.meta.author}"
                    
                  p "#{entry.meta.author} applied #{whose} to a story"
                excerpt : draft.data.text
                time    : do entry._id.getTimestamp
                class   : "success"
                    
            when "remove" then item
              icons   : [ "comment-alt", "remove" ]
              url     : "/story/#{entry.data._id}/"
              body    : "#{entry.meta.author} removed a story."
              excerpt : entry.data.text
              time    : do entry._id.getTimestamp
              class   : "danger"
            else item
              body    : "Something happened to a story"
              url     : "/story/entry.data._id"
              time    : do entry._id.getTimestamp

        else item
          time    : do entry._id.getTimestamp

          # document = entry.data
          # switch entry.model
          #   when "Story"
          #     a href: "/story/#{document._id}", class: "list-group-item", =>
          #       h4 class: "list-group-item-heading", =>
          #         i class: "icon-remove-sign", " "
          #         text "#{entry.meta.author} removed a story."
          #       p
          #         class: "list-group-item-text"
          #         _.string.prune document.text, 64
          #       p => small class: "pull-right", moment(entry._id.getTimestamp()).fromNow()
        
  #   a 
  #     href: "#!new-story"
  #     class: "list-group-item active"
  #     data:
  #       toggle: "modal"
  #       target: "#story-edit-dialog"
  #     =>
  #       h4 class: "list-group-item-heading", ->
  #         i class: "icon-star"
  #         text " Tell us your stroy."
  #       p class: "list-group-item-text", "Share your story with us. We will try to help."

  # @helper "story-edit-dialog", action: "/story/"
