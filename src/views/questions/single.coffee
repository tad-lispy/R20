View      = require "teacup-view"

layout    = require "../layouts/default"
moment    = require "moment"

debug     = require "debug"
$         = debug "R20:views:question"

module.exports = new View (data) ->
  {
    draft
    question
    stories
    csrf
    journal
  } = data
  # @page = title: if @draft? then @draft.text else if not @question.isNew then @question.text

  layout data, =>
    if draft?
      applied  = question._draft?.equals draft._id
      applied ?= no

      @div class: "alert alert-#{if applied then 'success' else 'info'} clearfix", =>
      
        @text "This is a draft proposed #{moment(draft._id.getTimestamp()).fromNow()} by #{draft.meta.author.name}. "
        if applied then @text "It is currently applied."

        @a
          href  : "/question/#{question._id}/"
          class : "btn btn-default btn-xs pull-right"
          =>
            @i class: "icon-arrow-left"
            @text " See actual question"

    # The question
    @div class: "jumbotron", =>
      if draft?
        @markdown draft.data.text

        @form
          action: "/question/#{question._id}/"
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
                  @i class: "icon-check-sign"
                  @text " " + "apply this draft"

              @dropdown items: [
                title : "make changes"
                href  : "#edit-question"
                icon  : "edit"
                data  :
                  toggle  : "modal"
                  target  : "#question-edit-dialog"
                  shortcut: "e"
              ,
                title : "show drafts"
                href  : "#show-drafts"
                icon  : "folder-close"
                data  :
                  toggle  : "modal"
                  target  : "#drafts-dialog"
                  shortcut: "d"
              ]

      else if question.isNew 
        @p class: "text-muted", =>
          @i class: "icon-info-sign"
          @text " Not published yet "

        @div class: "clearfix", => @div class: "btn-group pull-right", =>
          @button
            class: "btn btn-primary"
            data:
              toggle:   "modal"
              target:   "#drafts-dialog"
              shortcut: "d"
            =>
              @i class: "icon-folder-close"
              @text " see drafts "
              # @span class: "badge badge-info", @drafts.length

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
              @i class: "icon-comment"
              @text " sample stories (#{stories?.length or 0})"

          @dropdown items: [
            title : "make changes"
            href  : "#edit-question"
            icon  : "edit"
            data  :
              toggle  : "modal"
              target  : "#question-edit-dialog"
              shortcut: "e"
          ,
            title : "show drafts"
            href  : "#show-drafts"
            icon  : "folder-close"
            data  :
              toggle  : "modal"
              target  : "#drafts-dialog"
              shortcut: "d"
          ,
            title : "remove question"
            href  : "#remove-question"
            icon  : "remove-sign"
            data  :
              toggle  : "modal"
              target  : "#remove-dialog"
              shortcut: "del enter"
          ]
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
                      @i class: "icon-remove-sign"
                      @text " " + "Ok, drop it!"

    @modal 
      title : "Drafts of this question"
      id    : "drafts-dialog"
      =>
        @draftsTable
          drafts  : journal.filter (entry) -> entry.action is "draft" 
          applied : question?._draft
          chosen  : draft?._id
          root    : "/questions/"

    @modal 
      title : "Edit this question"
      id    : "question-edit-dialog"
      => @questionForm
        method  : "PUT"
        action  : "/questions/#{question._id}"
        csrf    : csrf
        question: question


    @h4 class: "text-muted", "Answers"
    @div class: "well", =>
      @p =>
        @i class: "icon-frown icon-4x"
        @text " Not implemented yet"

    if @stories?.length then @div
      class   : "modal fade"
      id      : "stories-dialog"
      tabindex: -1
      role    : "dialog"
      =>
        @div class: "modal-dialog", =>
          @div class: "modal-content", =>
            
            @div class: "modal-header", =>
              @button
                type  : "button"
                class : "close"
                data:
                  dismiss: "modal"
                aria:
                  hidden: true
                => @i class: "icon-remove"
              @h4 =>
                @text "Sample stories"
                @a 
                  class: "btn btn-link btn-sm"
                  href: "#stories-carousel"
                  data: slide: "prev"
                  => @i class: "icon icon-chevron-left"

                @a 
                  class: "btn btn-link btn-sm"
                  href: "#stories-carousel"
                  data: slide: "next"
                  => @i class: "icon icon-chevron-right"

            
            @div class: "modal-body", =>
              @div 
                id    : "stories-carousel"
                class : "carousel slide"
                data  :
                  ride  : "carousel"
                =>
                  @div class: "carousel-inner", => 
                    n = 0
                    for story in @stories
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
                          href: "/story/#{story.id}/"
                          =>
                            @i class: "icon-eye-open"
                            @text " got to story"
                            if story.questions.length - 1
                              @text " (#{story.questions.length - 1} other questions)"
                      n++
