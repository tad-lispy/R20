{
  renderable, tag, text, raw
  div, main, aside, nav
  ul, li
  h3, h4, p
  i, span, strong
  a
  form, button, input, textarea, label
  hr, br
  coffeescript
}         = require "teacup"
template  = require "./templates/default"
marked    = require "marked"

module.exports = renderable (data) ->
  template.call @, =>
    @scripts.push "/js/question-typeahead.js"
    @styles.push  "/css/typeahead-bs3-fix.css"

    # The story
    div class: "jumbotron", =>
      raw marked @story.text
      button
        class: "btn btn-default pull-right"
        data:
          toggle: "modal"
          target: "#story-edit-dialog"
        =>
          i class: "icon-edit"
          text " edit this story"

    @helper "story-edit-dialog", method: "PUT"

    # The questions
    div class: "panel panel-primary", =>
      div class: "panel-heading", =>
        h3
          class: "panel-title"
          "Legal questions abstracted from this story"

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
                placeholder : "Type to search or assign a question..."
                data        :
                  typeahead   : "question"
                  target      : "#assign-question-target"
                  source      : "#assign-question-template"
                value       : @query
              div class: "input-group-btn", =>
                button
                  class : "btn btn-primary"
                  type  : "submit"
                  =>
                    i class: "icon-search"
                    text " Search"

        div id: "assign-question-target"

        if @query
          p "Did you mean:"
          ul =>
            (li => a href: "##{n}", "suggestion #{n}") for n in [1..4]

    if @story.questions.length then div class: "list-group", =>
      for question in @story.questions
        a href: "/question/#{question._id}", class: "list-group-item", =>
          span class: "badge", question.answers?.length or 0
          h4
            class: "list-group-item-heading"
            question.text
          
          p =>
            text "Answers by: Kot Filemon, Katiusza"
            
          div class: "btn-group", =>
            form
              action: "/story/#{@story._id}/questions/#{question._id}"
              method: "post"
              =>
                @helper "csrf"
                input
                  type: "hidden"
                  name: "_method"
                  value: "DELETE"
                button
                  type: "submit"
                  class: "btn btn-danger btn-xs"
                  =>
                    i class: "icon-remove"
                    text " unasign"


      
    else div class: "alert alert-info", =>
      p =>
        text "No questions abstracted yet. "
        do br
        button 
          class : "btn btn-default"
          data  :
            toggle: "modal"
            target: "#new-question-dialog"
          =>
            text "assign some "
            i class : "icon-plus-sign"

    div class: "hide", id: "assign-question-template", =>
      do hr
      form
        action: "/story/#{@story._id}/questions"
        method: "post"
        =>
          div class: "input-group input-group-sm", =>
            input
              type: "hidden"
              name: "_id"
            input
              name    : "text"
              type    : "text"
              class   : "form-control"
              disabled: true

            span class:  "input-group-btn", =>
              button
                class: "btn btn-default sm-col-3"
                => 
                  i class: "icon-puzzle-piece"
                  text " assign"

    div
      class   : "modal fade"
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
              p "Add a new question"

