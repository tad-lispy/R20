{
  renderable, tag, text
  div, main, aside, nav
  ul, li
  h3, h4, p
  i, span, strong
  a
  form, button, input, textarea, label
  hr
  coffeescript
}         = require "teacup"
template  = require "./templates/default"
_         = require "underscore"
_.string  = require "underscore.string"
module.exports = renderable (data) ->
  @page = title: "Cases provided by our readers"
  
  template.call @, =>

    # div class: "panel panel-primary", =>
    #   div class: "panel-heading clearfix", =>
    #     h3
    #       class: "panel-title"
    #       "Stories submitted by readers"

    #   div class: "panel-body", =>
    form
      method: "GET"
      class : "form"
      =>
        div class: "input-group input-group-lg", =>
          input
            id          : "query"
            type        : "text"
            name        : "query"
            class       : "form-control"
            placeholder : "Type to search for story..."
            value       : @query
          div class: "input-group-btn", =>
            button
              class : "btn btn-primary"
              type  : "submit"
              =>
                i class: "icon-search"
                text " Search"
            @helper "dropdown", [
              title : "new story"
              icon  : "plus-sign"
              data  :
                toggle  : "modal"
                target  : "#story-edit-dialog"
                shortcut: "n"
              herf  : "#new-story"
            ]

    do hr

    if @stories.length then div class: "list-group", =>
      for story in @stories
        a href: "/story/#{story._id}", class: "list-group-item", =>
          span class: "badge", story.questions.length
          h4
            class: "list-group-item-heading"
            _.string.prune story.text, 256
            
        
    else div class: "alert alert-info", "Nothing like that found. Sorry :P"
    
    @helper "story-edit-dialog"