View      = require "teacup-view"
layout    = require "../layouts/default"

moment    = require "moment"
debug     = require "debug"
$         = debug "R20:views:answer"

module.exports = new View (data) ->
  {
    answer
    draft
    csrf
    journal
  } = data

  if draft then question = draft.data.question
  else          question = answer.question

  unless answer.isNew
    author = draft?.data.author or answer.author
    data.subtitle = "#{author.name} answers: #{question.text}"

  layout data, =>
    if draft?
      applied = Boolean answer._draft?.equals draft._id
      
      @draftAlert
        applied   : applied
        draft     : draft
        actualurl : "/questions/#{question._id}/answers/#{answer._id}"

    # # The question
    # @h4 class: "text-muted", =>
    #   @i  class: "icon-question-sign icon-fixed-width"
    #   @text question.text    
        

    # The answer
    @div class: "jumbotron", =>
      if draft?
        @markdown draft.data.text

        @form
          action: "/questions/#{question._id}/answers/#{draft.data._id}"
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
                  @i class: "icon-check-sign icon-fixed-width"
                  @text     "apply this draft"

              @dropdown items: [
                title : "make changes"
                href  : "#edit-answer"
                icon  : "edit"
                data  :
                  toggle  : "modal"
                  target  : "#answer-edit-dialog"
                  shortcut: "e"
              ]

      else if answer.isNew 
        @p class: "text-muted", =>
          @i class: "icon-info-sign icon-fixed-width"
          @text "Not published yet."
        @div class: "clearfix", => @div class: "btn-group pull-right", =>
          @a
            class : "btn btn-default"
            href  : "/questions/#{question._id}"
            => 
              @i class: "icon icon-arrow-left icon-fixed-width"
              @text "Back to question"

      else 
        @markdown answer.text

        @div class: "clearfix", => @div class: "btn-group pull-right", =>
          @a
            class : "btn btn-default"
            href  : "/questions/#{question._id}"
            => 
              @i class: "icon icon-arrow-left icon-fixed-width"
              @text "Back to question"
          @dropdown items: [
            title : "make changes"
            href  : "#edit"
            icon  : "edit"
            data  :
              toggle  : "modal"
              target  : "#answer-edit-dialog"
              shortcut: "e"
          ,
            title : "remove answer"
            href  : "#remove"
            icon  : "remove-sign"
            data  :
              toggle  : "modal"
              target  : "#remove-dialog"
              shortcut: "del enter"
          ]
        
    unless answer.isNew
      @modal 
        title : question.text
        id    : "answer-edit-dialog"
        =>
          @answerForm
            method  : "POST"
            action  : "/questions/#{question._id}/answers/#{answer._id}/drafts"
            csrf    : csrf
            answer  : draft?.data or answer
            question: question
        
    unless answer.isNew or draft?
      @modal 
        title : "Remove this answer?"
        id    : "remove-dialog"
        class : "modal-danger"
        =>
          @form
            method: "post"
            =>
              @input type: "hidden", name: "_csrf"   , value: csrf
              @input type: "hidden", name: "_method" , value: "DELETE"
                              
              @div class: "well", =>
                @markdown answer.text
              
              @p "Removing an answer is roughly equivalent to unpublishing it. It can be undone. All drafts will be preserved."

              @div class: "form-group", =>
                @button
                  type  : "submit"
                  class : "btn btn-danger"
                  =>
                    @i class: "icon-remove-sign icon-fixed-width"
                    @text "Remove!"
    
    @h4 class: "text-muted", =>
      @i class: "icon-time icon-fixed-width"
      @text "Versions"
    @draftsTable
            drafts  : journal.filter (entry) -> entry.action is "draft" 
            applied : answer?._draft
            chosen  : draft?._id
            root    : "/questions/#{question._id}/answers/"
