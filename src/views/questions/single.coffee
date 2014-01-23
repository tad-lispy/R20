View      = require "teacup-view"
layout    = require "../layouts/default"

moment    = require "moment"
_         = require "lodash"
debug     = require "debug"
$         = debug "R20:views:question"

module.exports = new View (data) ->
  {
    question
    draft
    stories
    answers
    journal
    participant
    csrf
  } = data

  data.classes ?= []
  data.classes.push "question"
  if draft then data.classes.push "draft"

  
  # TODO: if used as subtitle it shows twice on the page (as subtitle and in jumbotron)
  # subtitle =  if draft? then draft.text else
  #             if not question.isNew then question.text
  # if subtitle then data.subtitle = subtitle

  layout data, =>
    if draft?
      applied  = Boolean question._draft?.equals draft._id

      @draftAlert
        applied   : applied
        draft     : draft
        actualurl : "/questions/#{question._id}"

    # The question
    @div class: "jumbotron", =>
      if draft?
        @markdown draft.data.text

        @form
          action: "/questions/#{question._id}/"
          method: "POST"
          class : "clearfix"
          =>
            @input type: "hidden", name: "_method", value: "PUT"
            @input type: "hidden", name: "_csrf"  , value: data.csrf
            @input type: "hidden", name: "_draft" , value: draft._id
            
            @div class: "btn-group pull-right", =>
              @button
                class   : "btn btn-success"
                type    : "submit"
                disabled: applied
                data    : shortcut: "a a enter"
                =>
                  @i class: "fa fa-check-sign fa-fixed-width"
                  @text     "apply this draft"

              @dropdown items: [
                title : "make changes"
                href  : "#edit-question"
                icon  : "edit"
                data  :
                  toggle  : "modal"
                  target  : "#question-edit-dialog"
                  shortcut: "e"
              ]

      else if question.isNew 
        @p class: "text-muted", =>
          @i class: "fa fa-info-sign fa-fixed-width"
          @text "Not published yet."

      else 
        @strong question.text

        @div class: "clearfix", => @div class: "btn-group pull-right", =>
          @button
            class: "btn btn-default"
            disabled: not Boolean stories?.length
            data:
              toggle:   "modal"
              target:   "#stories-dialog"
              shortcut: "s"
            =>
              @i class: "fa fa-comment fa-fixed-width"
              @text " sample stories (#{stories?.length or 0})"

          @dropdown items: [
            title : "make changes"
            href  : "#edit"
            icon  : "edit"
            data  :
              toggle  : "modal"
              target  : "#question-edit-dialog"
              shortcut: "e"
          ,
            title : "show drafts"
            href  : "#drafts"
            icon  : "folder-close"
            data  :
              toggle  : "modal"
              target  : "#drafts-dialog"
              shortcut: "d"
          ,
            title : "remove question"
            href  : "#remove"
            icon  : "remove-sign"
            data  :
              toggle  : "modal"
              target  : "#remove-dialog"
              shortcut: "del enter"
          ]
        
    unless question.isNew and not draft?
      @modal 
        title : "Edit this question"
        id    : "question-edit-dialog"
        => @questionForm
          method  : "POST"
          action  : "/questions/#{question._id}/drafts"
          csrf    : csrf
          question: draft?.data or question

    if draft? or question.isNew
      @h4 class: "text-muted", =>
        @i class: "fa fa-timev fa-fixed-width"
        @text "Versions"
      @draftsTable
              drafts  : journal.filter (entry) -> entry.action is "draft" 
              applied : question?._draft
              chosen  : draft?._id
              root    : "/questions/"

    else
      @modal 
        title : "Remove this question?"
        id    : "remove-dialog"
        class : "modal-danger"
        =>
          @form
            method: "post"
            =>
              @input type: "hidden", name: "_csrf"   , value: csrf
              @input type: "hidden", name: "_method" , value: "DELETE"
                              
              @div class: "well", =>
                @markdown question.text
              
              @p "Removing a question is roughly equivalent to unpublishing it. It can be undone. All drafts will be preserved."

              @div class: "form-group", =>
                @button
                  type  : "submit"
                  class : "btn btn-danger"
                  =>
                    @i class: "fa fa-remove-sign fa-fixed-width"
                    @text " " + "Remove!"

      # Drafts modal is used in published question view only.
      # In other views (drafts or unpublished) drafts table is below text.
      @modal 
        title : "Drafts of this question"
        id    : "drafts-dialog"
        =>
          @draftsTable
            drafts  : journal.filter (entry) -> entry.action is "draft" 
            applied : question?._draft
            chosen  : draft?._id
            root    : "/questions/"

      @h4 class: "text-muted", =>
        @i class: "fa fa-puzzle-piece fa-fixed-width"
        @text "Answers"
      if answers.length then for answer in answers
        @div class: "panel panel-default", id: "answer-#{answer._id}", =>
          @div class: "panel-heading clearfix", =>
            @strong class: "text-muted", =>
              @text "by #{answer.author?.name or "unknown author"} (#{moment(answer._id.getTimestamp()).fromNow()}):"
            @a
              href  : "/questions/#{question._id}/answers/#{answer._id}"
              class: "btn btn-xs pull-right"
              => @i class: "fa fa-fullscreen"
              
          @div class: "panel-body clearfix", =>
            
            @markdown answer.text
            
          # TODO: use client side js to deal with modals and forms
          @modal 
            title : "Edit answer by #{answer.author?.name or "unknown author"}"
            id    : "answer-#{answer._id}-edit-dialog"
            => @answerForm
              method  : "POST"
              action  : "/questions/#{question._id}/answers/#{answer._id}/drafts"
              csrf    : csrf
              answer  : answer

      
      else @div class: "well", =>
          @p =>
            @i class: "fa fa-frown fa-4x"
            @text " No answers to this question yet."

      # Display new answer form unless this participant already answered this question
      if participant? then unless  (_.any answers, (answer) -> answer.author?._id?.equals participant?._id)
        if answers.drafted? then @div class: "alert alert-info", =>
          @text "There is at least one draft of your answer to this question"
          @a
            href  : "/questions/#{question._id}/answers/#{answers.drafted._id}"
            class: "btn btn-default btn-xs pull-right"
            =>
              @i class: "fa fa-eye-open fa-fixed-width"
              @text "see drafts"

        else @form
          id    : "new-answer"
          method: "POST"
          action: "/questions/#{question._id}/answers"
          =>
            @div class: "form-group", =>
              @label for: "text", "Have an answer? Please share it!"
              @textarea 
                class       : "form-control"
                name        : "text"
                placeholder : "Your answer..."
                data        :
                  shortcut    : "a"
                  
            @div class: "form-group", =>
              @button
                type  : "submit"
                class : "btn btn-primary"
                =>
                  @i class: "fa fa-check-sign"
                  @text " " + "send"
            @input type: "hidden", name: "_csrf", value: csrf

    if stories?.length then @modal
      title : "Sample stories"
      id    : "stories-dialog"
      =>
        @div class: "modal-body", =>
          @div 
            id      : "stories-carousel"
            class   : "carousel slide"
            data    :
              ride    : "carousel"
              interval: "false"
            =>
              @div class: "carousel-inner", => 
                for story, n in stories
                  @div class: "item #{if n is 0 then 'active' else ''}", =>
                    @div
                      style: """
                        height  : 200px;
                        overflow: hidden;
                        overflow-y: auto;
                        margin-bottom: 10px;
                      """
                      =>
                        @markdown story.text
                    @a
                      class: "btn btn-info"
                      href: "/stories/#{story.id}/"
                      =>
                        @i class: "fa fa-eye-open"
                        @text " got to story"
                        if story.questions.length - 1
                          @text " (#{story.questions.length - 1} other questions)"

                    if stories.length > 1 then @div class: "btn-group pull-right", ->
                      @a 
                        class: "btn btn-default"
                        href: "#stories-dialog"
                        data: slide: "prev"
                        => @i class: "fa fa-chevron-left"

                      @span
                        disabled: true
                        class   : "btn"
                        "#{n+1} / #{stories.length}"

                      @a 
                        class: "btn btn-default"
                        href: "#stories-carousel"
                        data: slide: "next"
                        => @i class: "fa fa-chevron-right"


