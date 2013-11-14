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
    @scripts.push "/js/assign-question.js"
    # @scripts.push "/js/question-typeahead.js"
    # @styles.push  "/css/typeahead-bs3-fix.css"

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
        strong
          class: "panel-title"
          "Legal questions abstracted from this story"

        div class: "btn-group pull-right", =>
          button
            type  : "button"
            class : "btn btn-default btn-xs"
            data  :
              toggle: "collapse"
              target: "#assignment-list"
            =>
              i class: "icon-plus-sign"

      div 
        class : "panel-body collapse"
        id    : "assignment-list"
        =>
          div class: "well", =>
            # Search form
            form

              data        :
                search      : "question"
                target      : "#assign-questions-list"
                source      : "#assign-question-template"
              =>
                div class: "form-group", =>
                  div class: "input-group input-group-sm", =>
                    input
                      type        : "text"
                      name        : "text"
                      class       : "form-control"
                      placeholder : "Type to search for a question to assign..."
                      value       : @query
                    div class: "input-group-btn", =>
                      button
                        class   : "btn btn-primary"
                        type    : "submit"
                        disabled: true
                        =>
                          i class: "icon-search"
                          text " Search"

            div id: "assign-questions-list", =>
              div class: "hide", id: "assign-question-template", =>
                form
                  action: "/story/#{@story._id}/questions"
                  method: "post"
                  =>
                    div class: "form-group", =>
                      input
                        type: "hidden"
                        name: "_id"
                      @helper "csrf"
                      
                      button
                        type    : "submit"
                        class   : "btn btn-block"
                        data    : fill: "text"

            div class: "form-group", =>
              button
                type    : "button"
                class   : "btn btn-block btn-primary"
                data    :
                  toggle  : "modal"
                  target  : "#question-edit-dialog"
                =>
                  i class: "icon-star"
                  text " Add a brand new question"

            @helper "question-edit-dialog",
              action: "/question/"
              # TODO: after submission redirect back to this page!


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

