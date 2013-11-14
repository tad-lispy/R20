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
  template.call @, =>

    div class: "panel panel-primary", =>
      div class: "panel-heading", =>
        h3
          class: "panel-title"
          "Legal questions abstracted from reader stories"

      div class: "panel-body", =>
        form
          method: "GET"
          =>
            div class: "input-group input-group-lg", =>
              input
                id          : "question"
                type        : "text"
                name        : "text"
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

                button
                  class: "btn btn-default"
                  data:
                    toggle: "modal"
                    target: "#question-edit-dialog"
                  =>
                    i class: "icon-plus-sign-alt"
                    text " Add"


    if @questions.length then div class: "list-group", =>
      for question in @questions
        a href: "/question/#{question._id}", class: "list-group-item", =>
          span class: "badge", question.answers.length
          h4
            class: "list-group-item-heading"
            question.text
          
          p "Answers by: Kot Filemon, Katiusza"
      
    else div class: "alert alert-info", "Nothing like that found. Sorry :P"    
    
    @helper "question-edit-dialog"