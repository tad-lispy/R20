{
  renderable, tag, text, raw
  div, main, aside, nav
  img
  ul, ol, li
  h1, h2, h3, h4, p
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
$         = debug "R20:views:question"

module.exports = renderable (data) ->
  # @page = title: if @draft? then @draft.text else if not @question.isNew then @question.text

  template.call @, =>
    if @draft?
      applied = @question._draft?.equals @draft._id

      div class: "alert alert-#{if applied then 'success' else 'info'} clearfix", =>
      
        text "This is a draft proposed #{moment(@draft._id.getTimestamp()).fromNow()} by #{@draft.meta.author}. "
        if applied then text "It is currently applied."

        a
          href  : "/question/#{@question._id}/"
          class : "btn btn-default btn-xs pull-right"
          =>
            i class: "icon-arrow-left"
            text " See actual question"

    # The story
    div class: "jumbotron", =>
      if @draft?
        markdown @draft.data.text

        form
          action: "/question/#{@question._id}/"
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
                "edit-question"
                "show-question-drafts"
              ]

      else if @question.isNew 
        p class: "text-muted", =>
          i class: "icon-info-sign"
          text " Not published yet "

        div class: "clearfix", => div class: "btn-group pull-right", =>
          button
            class: "btn btn-primary"
            data:
              toggle: "modal"
              target: "#question-drafts-dialog"
            =>
              i class: "icon-folder-close"
              text " see drafts "
              # span class: "badge badge-info", @drafts.length

      else 
        strong @question.text

        div class: "clearfix", => div class: "btn-group pull-right", =>
          button
            class: "btn btn-default"
            data:
              toggle: "modal"
              target: "#question-edit-dialog"
            =>
              i class: "icon-edit"
              text " make changes"

          @helper "dropdown", [
            "show-question-drafts"
            # "drop-question"
          ]




    h4 class: "text-muted", "Answers"
    div class: "well", =>
      p =>
        i class: "icon-frown icon-4x"
        text " Not implemented yet"


    # div 
    #   id    : "stories-carousel"
    #   class : "carousel slide"
    #   data  :
    #     ride  : "carousel"
    #   =>
    #     ol class: "carousel-indicators", =>
    #       n = 0
    #       for story in @question.stories
    #         li 
    #           class: "active" if i is 0
    #           data:
    #             target: "stories-carousel"
    #             "slide-to": n++

    #     div class: "carousel-inner", =>
    #       n = 0
    #       for story in @question.stories
    #         div 
    #           class: "item #{'active' if i is 0}"
    #           style: "background: red"
    #           =>
    #             img style: "width: 1200px; height: 600px; background: red"
    #             # raw marked story.text
    #         n++

    #     a 
    #       class: "left carousel-control"
    #       href: "#stories-carousel"
    #       data: slide: "prev"
    #       => i class: "icon-chevron-left"
    #     a 
    #       class: "right carousel-control"
    #       href: "#stories-carousel"
    #       data: slide: "next"
    #       => i class: "icon-chevron-right"

    # if @question.stories.length
    #   h4 class: "text-muted", "Sample stories"
    #   div class: "list-group", =>
    #     for story in @question.stories
    #       a href: "/story/#{story._id}", class: "list-group-item", =>
    #         span class: "badge", story.questions?.length or 0
    #         raw marked story.text
                      
    #       # div class: "btn-group", =>
    #       #   form
    #       #     action: "/story/#{@story._id}/questions/#{question._id}"
    #       #     method: "post"
    #       #     =>
    #       #       input
    #       #         type: "hidden"
    #       #         name: "_method"
    #       #         value: "DELETE"
    #       #       button
    #       #         type: "submit"
    #       #         class: "btn btn-danger btn-xs"
    #       #         =>
    #       #           i class: "icon-remove"
    #       #           text " unasign"


      
    # # else div class: "alert alert-info", =>
    # #   p =>
    # #     text "No questions abstracted yet. "
    # #     do br
    # #     button 
    # #       class : "btn btn-default"
    # #       data  :
    # #         toggle: "modal"
    # #         target: "#new-question-dialog"
    # #       =>
    # #         text "assign some "
    # #         i class : "icon-plus-sign"

    # # div class: "hide", id: "assign-question-template", =>
    # #   do hr
    # #   form
    # #     action: "/story/#{@story._id}/questions"
    # #     method: "post"
    # #     =>
    # #       div class: "input-group input-group-sm", =>
    # #         input
    # #           type: "hidden"
    # #           name: "_id"
    # #         input
    # #           name    : "text"
    # #           type    : "text"
    # #           class   : "form-control"
    # #           disabled: true

    # #         span class:  "input-group-btn", =>
    # #           button
    # #             class: "btn btn-default sm-col-3"
    # #             => 
    # #               i class: "icon-puzzle-piece"
    # #               text " assign"

    # # div
    # #   class   : "modal fade"
    # #   id      : "new-question-dialog"
    # #   tabindex: -1
    # #   role    : "dialog"
    # #   =>
    # #     div class: "modal-dialog", =>
    # #       div class: "modal-content", =>
            
    # #         div class: "modal-header", =>
    # #           button
    # #             type  : "button"
    # #             class :"close"
    # #             data:
    # #               dismiss: "modal"
    # #             aria:
    # #               hidden: true
    # #             -> i class: "icon-remove"
    # #           h4 "A brand new question?"
            
    # #         div class: "modal-body", =>
    # #           p "Add a new question"

