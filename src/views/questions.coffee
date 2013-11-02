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
  helper = (name, context) =>
    fn = require "./helpers/" + name
    context ?= @
    fn.call context

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
                    target: "#new-question-dialog"
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
        
    
    div
      # TODO: a helper
      class   : "modal modal-primary fade"
      id      : "new-question-dialog"
      tabindex: -1
      role    : "dialog"
      =>
        div class: "modal-dialog", =>
          div class: "modal-content", =>
            
            div class: "modal-header", =>
              button
                type  : "button"
                class :"close"
                data:
                  dismiss: "modal"
                aria:
                  hidden: true
                -> i class: "icon-remove"
              h4 "A brand new question?"
            
            div class: "modal-body", =>
              p "You are about to add a new legal question. Are you sure it's not already there?"

              form method: "post", =>
                div class: "form-group", =>
                  label for: "text", "New question text:"
                  input
                    type        : "text"
                    name        : "text"
                    class       : "form-control"
                    placeholder : "Enter the text of a new question..."


