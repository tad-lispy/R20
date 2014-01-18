View      = require "teacup-view"
layout    = require "../layouts/default"

moment    = require "moment"
debug     = require "debug"
$         = debug "R20:views:story"

module.exports = new View (data) ->
  {
    story
    draft
    csrf
    query
    journal
  } = data
  data.classes  ?=                []
  data.classes.push               "story"
  if draft then data.classes.push "draft"


  data.subtitle = "The case of #{ moment(story._id.getTimestamp()).format 'LL' }"
  
  layout data, =>
    data.scripts.push "/js/assign-question.js"
    data.scripts.push "//cdnjs.cloudflare.com/ajax/libs/jquery.form/3.45/jquery.form.min.js"


    if draft?
      applied  = Boolean story._draft?.equals draft._id
      
      @draftAlert
        applied   : applied
        draft     : draft
        actualurl : "/stories/#{story._id}"

    # The story
    @div class: "jumbotron", =>
      if draft
        @markdown draft.data.text

        @form
          action: "/stories/#{story._id}/"
          method: "POST"
          class : "clearfix"
          =>
            @input type: "hidden", name: "_method"  , value: "PUT"
            @input type: "hidden", name: "_csrf"    , value: csrf
            @input type: "hidden", name: "_draft"   , value: draft._id
            
            @div class: "btn-group pull-right", =>
              @button
                class   : "btn btn-success"
                type    : "submit"
                disabled: applied
                data    : shortcut: "a a enter"
                =>
                  @i class: "icon-check-sign"
                  @text " apply this draft"

              @dropdown items: [
                title : "make changes"
                href  : "#edit-story"
                icon  : "edit"
                data  :
                  toggle  : "modal"
                  target  : "#story-edit-dialog"
                  shortcut: "e"
              ]

      else if story.isNew 
        @p class: "text-muted", =>
          @i class: "icon-info-sign"
          @text " Not published yet "

      else 
        @markdown story.text

        @div class: "clearfix", => @div class: "btn-group pull-right", =>
          @button
            class: "btn btn-default"
            data:
              toggle  : "modal"
              target  : "#story-edit-dialog"
              shortcut: "e"
            =>
              @i class: "icon-edit icon-fixed-width"
              @text " make changes"

          @dropdown items: [
            title : "show drafts"
            href  : "#show-drafts"
            icon  : "folder-close"
            data  :
              toggle  : "modal"
              target  : "#drafts-dialog"
              shortcut: "d"
          ,
            title : "remove story"
            href  : "#remove"
            icon  : "remove-sign"
            data  :
              toggle  : "modal"
              target  : "#remove-dialog"
              shortcut: "del enter"
          ]

    unless story.isNew and not draft?
      @modal 
        title : "Edit story"
        id    : "story-edit-dialog"
        =>
          @p "Could it be told beter? Make changes if so."
          @storyForm
            method  : "POST"
            action  : "/stories/#{story._id}/drafts"
            story   : draft?.data or story
            csrf    : csrf

    if draft? or story.isNew
      @h4 class: "text-muted", =>
        @i class: "icon-timev icon-fixed-width"
        @text "Versions"
      @draftsTable
        drafts  : journal.filter (entry) -> entry.action is "draft" 
        applied : story?._draft
        chosen  : draft?._id
        root    : "/stories/"
    
    else
      @modal 
        title : "Drafts of this story"
        id    : "drafts-dialog"
        =>
          @draftsTable
            drafts  : journal.filter (entry) -> entry.action is "draft" 
            applied : story?._draft
            chosen  : draft?._id
            root    : "/stories/"

      @modal 
        title : "Remove this story?"
        id    : "remove-dialog"
        class : "modal-danger"
        =>
          @form
            method: "post"
            =>
              @input type: "hidden", name: "_csrf"   , value: csrf
              @input type: "hidden", name: "_method" , value: "DELETE"
                              
              @div class: "well", =>
                @markdown story.text
              
              @p "Removing a story is roughly equivalent to unpublishing it. It can be undone. All drafts will be preserved."

              @div class: "form-group", =>
                @button
                  type  : "submit"
                  class : "btn btn-danger"
                  =>
                    @i class: "icon-remove-sign icon-fixed-width"
                    @text "Remove!"

      # The questions
      @div class: "panel panel-primary", =>
        @div class: "panel-heading", =>
          @strong
            class: "panel-title"
            "Legal questions abstracted from this story"

          @div class: "btn-group pull-right", =>
            @button
              type  : "button"
              class : "btn btn-default btn-xs"
              data  :
                toggle  : "collapse"
                target  : "#assignment-list"
                shortcut: "a q"
              =>
                @i class: "icon-plus-sign"
                @text " assign"

        @div 
          class : "panel-body collapse"
          id    : "assignment-list"
          =>
            @div class: "well", =>
              # Search form
              @form
                data        :
                  search      : "questions"
                  target      : "#assign-questions-list"
                  source      : "#assign-question-template"
                =>
                  @div class: "form-group", =>
                    @div class: "input-group input-group-sm", =>
                      @input
                        type        : "text"
                        name        : "query"
                        class       : "form-control"
                        placeholder : "Type to search for a question to assign..."
                        value       : query
                      @div class: "input-group-btn", =>
                        @button
                          class   : "btn btn-primary"
                          type    : "submit"
                          disabled: true
                          =>
                            @i class: "icon-search"
                            @text " Search"

              @div id: "assign-questions-list", =>
                @div class: "hide", id: "assign-question-template", =>
                  @form
                    action: "/stories/#{story._id}/questions"
                    method: "post"
                    =>
                      @div class: "form-group", =>
                        @input
                          type  : "hidden"
                          name  : "_id"
                        
                        @input
                          type  : "hidden"
                          name  : "_csrf"
                          value : csrf
                        
                        
                        @button
                          type    : "submit"
                          class   : "btn btn-block"
                          data    : fill: "text"

              @div class: "form-group", =>
                @button
                  type    : "button"
                  class   : "btn btn-block btn-primary"
                  data    :
                    toggle  : "modal"
                    target  : "#new-question-dialog"
                    shortcut: "n q"
                  =>
                    @i class: "icon-star"
                    @text " Add a brand new question"

              @modal """
               "question-edit-dialog",
                action: "/question/"
                # TODO: after submission redirect back to this page!
              """


        @div class: "list-group", =>
          if story.questions.length
            for question in story.questions
              @a href: "/questions/#{question._id}", class: "list-group-item", =>
                @span class: "badge", question.answers?.length or 0
                @h4
                  class: "list-group-item-heading"
                  question.text
                
                if question.answers.length then @p =>
                  @text "Answers by: "
                  for answer in question.answers
                    @text answer.author.name
                else @p class: "text-muted", "No answers yet"
                  
                @div class: "btn-group", =>
                  @form
                    action: "/stories/#{story._id}/questions/#{question._id}"
                    method: "post"
                    =>
                      @input 
                        type  : "hidden"
                        name  : "_csrf"
                        value : csrf
                      @input
                        type  : "hidden"
                        name  : "_method"
                        value : "DELETE"
                      @button
                        type  : "submit"
                        class : "btn btn-danger btn-xs"
                        =>
                          @i class: "icon-remove"
                          @text " unasign"

          else @a
            href: "#assign-question"
            class: "list-group-item"
            data  :
              toggle: "collapse"
              target: "#assignment-list"
            =>
              @h4 class: "text-muted", =>
                @text " No questions abstracted yet. "
              @p class: "text-muted", =>
                @i class: "icon-plus-sign"
                @text " Do it now!"

      @modal
        id      : "new-question-dialog"
        title   : "Add new question"
        =>
          @questionForm
            action  : "/questions/"
            method  : "POST"
            csrf    : csrf