{
  renderable, tag, text
  div, main, aside, nav
  ul, li
  h3, h4, p
  i, span
  a
  form, button, input, textarea, label
  hr
  coffeescript
} = require "teacup"
template  = require "./templates/default"

module.exports = renderable (data) ->
  @page = title: "Legal questions of interest"
  
  template.call @, =>
  
    form
      method: "GET"
      =>
        div class: "input-group input-group-lg", =>
          input
            id          : "query"
            type        : "text"
            name        : "query"
            class       : "form-control"
            placeholder : "Type to search or create new..."
            value       : @query
          div class: "input-group-btn", =>
            button
              class : "btn btn-primary"
              type  : "submit"
              =>
                i class: "icon-search"
                text " Search"

            @helper "dropdown", ["new-question"]

    do hr
    
    if @questions.length then div class: "list-group", =>
      for question in @questions
        a href: "/question/#{question._id}", class: "list-group-item", =>
          # span class: "badge", question.answers.length
          h4
            class: "list-group-item-heading"
            question.text
          
          p "Answers by: Kot Filemon, Katiusza"
      
    else div class: "alert alert-info", "Nothing like that found. Sorry :P"    
    
    @helper "question-edit-dialog"