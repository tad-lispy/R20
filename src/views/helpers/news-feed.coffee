{
  renderable, render
  tag, text
  div, span, pre
  h3, h4, p
  hr
  a, i, small, strong, em
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
        if typeof options.excerpt is "function" then do options.excerpt
        else div
          style: """          
            text-overflow: ellipsis;
            white-space: nowrap;
            overflow: hidden;
          """
          => strong _.string.stripTags render => markdown options.excerpt
      
    p class: "text-right", => small moment(options.time).fromNow()

module.exports = renderable ->
  div class: "list-group", =>
    for entry in @entries

      switch entry.model 
        # TODO: OMG DRY!
        
        # Stories related entries
        # -----------------------

        when "Story" then switch entry.action
        
          when "draft" then item
            icons   : [ "comment-alt", "plus-sign" ]
            url     : "/story/#{entry.data._id}/draft/#{entry._id}"
            body    : "#{entry.meta.author.name} wrote a draft for a story."
            excerpt : entry.data.text
            time    : do entry._id.getTimestamp
            class   : "info"
      
          when "apply" 
            draft = entry.data._draft
            item 
              icons   : [ "comment-alt", "ok-circle" ]
              url     : "/story/#{draft.data._id}/"
              body    : ->
                whose = if draft.meta.author._id.equals entry.meta.author._id
                  "his own draft"
                else
                  " a draft by #{draft.meta.author.name}"
                p "#{entry.meta.author.name} applied #{whose} to a story"
              excerpt : draft.data.text
              time    : do entry._id.getTimestamp
              class   : "success"
                  
          when "remove" then item
            icons   : [ "comment-alt", "remove" ]
            url     : "/story/#{entry.data._id}/"
            body    : "#{entry.meta.author.name} removed a story."
            excerpt : entry.data.text
            time    : do entry._id.getTimestamp
            class   : "danger"

          when "reference" 
            item
              icons   : [ "comment-alt", "question-sign" ]
              url     : "/story/#{entry.data.main_doc._id}/"
              body    : "#{entry.meta.author.name} referenced a question to a story."
              excerpt : ->
                div
                  style: """          
                    text-overflow: ellipsis;
                    white-space: nowrap;
                    overflow: hidden;
                  """
                  =>
                    strong "S: " 
                    em _.string.stripTags render =>
                      markdown entry.data.main_doc.text
                div
                  style: """          
                    text-overflow: ellipsis;
                    white-space: nowrap;
                    overflow: hidden;
                  """
                  =>
                    strong "Q: " + _.string.stripTags render =>
                      markdown entry.data.referenced_doc.text
              time    : do entry._id.getTimestamp
              class   : "success"
          
          when "unreference" then item
            icons   : [ "comment-alt", "question-sign" ]
            url     : "/story/#{entry.data.main_doc._id}/"
            body    : "#{entry.meta.author.name} removed a question from a story."
            excerpt : ->
              div
                style: """          
                  text-overflow: ellipsis;
                  white-space: nowrap;
                  overflow: hidden;
                """
                =>
                  strong "S: " 
                  em _.string.stripTags render =>
                    markdown entry.data.main_doc.text
              div
                style: """          
                  text-overflow: ellipsis;
                  white-space: nowrap;
                  overflow: hidden;
                """
                =>
                  strong "Q: "
                  strong style: "text-decoration: line-through", _.string.stripTags render =>
                    markdown entry.data.referenced_doc.text
            time    : do entry._id.getTimestamp
            class   : "danger"

          else item
            body    : "Something (#{entry.action}) happened to a story"
            url     : "/story/#{entry.data._id}"
            time    : do entry._id.getTimestamp


        # Questions related entries
        # -------------------------

        when "Question" then switch entry.action

          when "draft" then item
            icons   : [ "question-sign" ]
            url     : "/question/#{entry.data._id}/draft/#{entry._id}"
            body    : "#{entry.meta.author.name} wrote a new draft for a question."
            excerpt : entry.data.text
            time    : do entry._id.getTimestamp
            class   : "info"
          
          when "apply" 
            draft = entry.data._draft
            item 
              icons   : [ "question-sign" ]
              url     : "/question/#{draft.data._id}/"
              body    : ->
                whose = if draft.meta.author._id.equals entry.meta.author._id
                  "his own draft"
                else
                  " a draft by #{draft.meta.author.name}"
                  
                p "#{entry.meta.author.name} applied #{whose} to a question"
              excerpt : draft.data.text
              time    : do entry._id.getTimestamp
              class   : "success"
                  
          when "remove" then item
            icons   : [ "question-sign" ]
            url     : "/question/#{entry.data._id}/"
            body    : "#{entry.meta.author.name} removed a question."
            excerpt : entry.data.text
            time    : do entry._id.getTimestamp
            class   : "danger"
          
          else item
            body    : "Something (#{entry.action}) happened to a question"
            url     : "/question/#{entry.data._id}"
            time    : do entry._id.getTimestamp

        else item
          time    : do entry._id.getTimestamp
