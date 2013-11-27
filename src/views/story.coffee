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
markdown  = require "./helpers/markdown"
moment    = require "moment"
debug     = require "debug"
$         = debug "R20:views:story"

module.exports = renderable (data) ->
  @page = title: "The case of #{ moment(@story._id.getTimestamp()).format 'LL' }"

  template.call @, =>
    @scripts.push "/js/assign-question.js"
    @scripts.push "//cdnjs.cloudflare.com/ajax/libs/jquery.form/3.45/jquery.form.min.js"
    # @scripts.push "/js/question-typeahead.js"
    # @styles.push  "/css/typeahead-bs3-fix.css"

    if @draft?
      applied  = @story._draft?.equals @draft._id
      applied ?= no
      
      div class: "alert alert-#{if applied then 'success' else 'info'} clearfix", =>
      
        text "This is a draft proposed #{moment(@draft._id.getTimestamp()).fromNow()} by #{@draft.meta.author}. "
        if applied then text "It is currently applied."

        a
          href  : "/story/#{@story._id}/"
          class : "btn btn-default btn-xs pull-right"
          =>
            i class: "icon-arrow-left"
            text " See actual story"

    # The story
    div class: "jumbotron", =>
      if @draft
        markdown @draft.data.text

        form
          action: "/story/#{@story._id}/"
          method: "POST"
          class : "clearfix"
          =>
            input type: "hidden", name: "_method",  value: "PUT"
            @helper "csrf"
            input type: "hidden", name: "_draft",    value: @draft._id
            
            div class: "btn-group pull-right", =>
              button
                class   : "btn btn-success"
                type    : "submit"
                disabled: applied
                =>
                  i class: "icon-check-sign"
                  text " apply this draft"

              @helper "dropdown", [
                title : "make changes"
                href  : "#edit-story"
                icon  : "edit"
                data  :
                  toggle: "modal"
                  target: "#story-edit-dialog"
              ,
                title : "show drafts"
                href  : "#show-drafts"
                icon  : "folder-close"
                data  :
                  toggle: "modal"
                  target: "#drafts-dialog"
              ]

        @helper "story-edit-dialog",
          method  : "PUT"
          action  : "/story/#{@story._id}"
          document: @draft.data

      else if @story.isNew 
        p class: "text-muted", =>
          i class: "icon-info-sign"
          text " Not published yet "

        div class: "clearfix", => div class: "btn-group pull-right", =>
          button
            class: "btn btn-primary"
            data:
              toggle: "modal"
              target: "#drafts-dialog"
            =>
              i class: "icon-folder-close"
              text " see drafts "
              # span class: "badge badge-info", @drafts.length

      else 
        markdown @story.text

        div class: "clearfix", => div class: "btn-group pull-right", =>
          button
            class: "btn btn-default"
            data:
              toggle: "modal"
              target: "#story-edit-dialog"
            =>
              i class: "icon-edit"
              text " make changes"

          @helper "dropdown", [
            title : "show drafts"
            href  : "#show-drafts"
            icon  : "folder-close"
            data  :
              toggle: "modal"
              target: "#drafts-dialog"
          ,
            title : "drop story"
            href  : "#drop-story"
            icon  : "remove-sign"
            data  :
              toggle: "modal"
              target: "#story-drop-dialog"
          ]

          @helper "story-edit-dialog",
            method  : "PUT"
            action  : "/story/#{@story._id}"

          @helper "story-drop-dialog"

    @helper "drafts-dialog", type: "story"

    if not @story.isNew and not @draft
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
                text " assign"

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
                        name        : "query"
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


        div class: "list-group", =>
          if @story.questions.length
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

          else a
            href: "#assign-question"
            class: "list-group-item"
            data  :
              toggle: "collapse"
              target: "#assignment-list"
            =>
              h4 class: "text-muted", =>
                text " No questions abstracted yet. "
              p class: "text-muted", =>
                i class: "icon-plus-sign"
                text " Do it now!"

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

