View      = require "teacup-view"
_         = require "lodash"
_.string  = require "underscore.string"
moment    = require "moment"

debug     = require "debug"
$         = debug "R20:helpers:news_feed"


item      = new View
  components: __dirname
  View (options = {}) ->
    options = _.defaults options,
      url   : "#"
      icons : [ "cogs" ]
      class : "default"
      body  : => @translate "Something happened."
      footer: if options.time? then moment(options.time).fromNow() else ""

    @div class: "panel panel-default", => 
      @a 
        href  : options.url
        class: "panel-body list-group-item", =>
        =>
          @div class: "media", =>
            
            @div class: "pull-left text-" + options.class, =>
              @span class: "media-object fa-stack fa-lg", =>
                @i class: "fa fa-stack-2x fa-" + options.icons[0]
                @i class: "fa fa-stack-1x fa-" + options.icons[1] if options.icons[1]?
            
            @div class: "media-body", =>
              if typeof options.body is "function" then do options.body
              else @p options.body
                
              if options.excerpt? 
                if typeof options.excerpt is "function" then do options.excerpt
                else @div class: "excerpt", =>
                  @strong _.string.stripTags @render => @markdown options.excerpt
          
          @p class: "text-right", => 
            @small options.footer

module.exports = new View
  components: __dirname
  (options = {}) ->
    
    _(options).defaults
      entries: []

    {
      entries
    } = options

    @div class: "news-feed", =>
      for entry in entries

        switch entry.model 
          # TODO: OMG DRY!
          
          # Stories related entries
          # -----------------------

          when "Story" then switch entry.action
          
            # when "draft" then item
            #   icons   : [ "comment-o", "plus" ]
            #   url     : "/stories/#{entry.data._id}/drafts/#{entry._id}"
            #   body    : => @translate "%s wrote a draft for a story.",
            #     entry.meta?.author?.name
            #   excerpt : entry.data.text
            #   time    : do entry._id.getTimestamp
            #   class   : "info"
        
            when "apply" 
              applied = entry.data._entry
              switch applied.action
                when "draft"
                  item 
                    icons   : [ "comment-o", "check" ]
                    url     : "/stories/#{applied.data._id}/"
                    body    : =>
                      @p => 
                        if applied.meta.author._id.equals entry.meta.author._id
                          @translate "%s applied his own draft to a story",
                            entry.meta?.author?.name
                        else
                          @translate "%s applied a draft by %s to a story",
                            entry.meta?.author?.name
                            applied.meta.author.name
                    excerpt : applied.data.text
                    time    : do entry._id.getTimestamp
                    class   : "success"
                when "reference"
                  item
                    icons   : [ "link" ]
                    url     : "/stories/#{applied.data.main?._id or applied.populated "data.main"}/"
                    footer  : "#{entry.meta?.author?.name} applied a question reference to a story."
                    body    : =>
                      @div class: "excerpt", =>
                        @i class: "fa fa-fw text-muted fa-comment" 
                        @em _.string.stripTags @render =>
                          @markdown applied.data.main?.text or "UNPUBLISHED"
                      @div
                        style: """          
                          text-overflow: ellipsis;
                          white-space: nowrap;
                          overflow: hidden;
                        """
                        =>
                          @i class: "fa fa-fw text-muted fa-question-circle" 
                          @strong _.string.stripTags @render =>
                            @markdown applied.data.referenced?.text or "UNPUBLISHED"
                    time    : do entry._id.getTimestamp
                    class   : "info"

                # when "unreference"                   
                #   item
                #     icons   : [ "unlink" ]
                #     url     : "/stories/#{applied.data.main?._id or applied.populated "data.main"}/"
                #     footer  : "#{applied.meta?.author?.name} removed a question from a story."
                #     body    : =>
                #       @div class: "excerpt", =>
                #         @i class: "fa fa-fw text-muted fa-comment" 
                #         @em _.string.stripTags @render =>
                #           @markdown applied.data.main?.text or "UNPUBLISHED"
                #       @div
                #         style: """          
                #           text-overflow: ellipsis;
                #           white-space: nowrap;
                #           overflow: hidden;
                #         """
                #         =>
                #           @i class: "fa fa-fw text-muted fa-question-circle" 
                #           @strong _.string.stripTags @render =>
                #             @markdown applied.data.referenced?.text or "UNPUBLISHED"
                #     time    : do entry._id.getTimestamp
                #     class   : "danger"

                    
            # when "remove" then item
            #   icons   : [ "comment-o", "times" ]
            #   url     : "/stories/#{entry.data._id}/"
            #   body    : "#{entry.meta?.author?.name} removed a story."
            #   excerpt : entry.data.text
            #   time    : do entry._id.getTimestamp
            #   class   : "danger"

            # # Don't show that ATM - references are auto - applied. Info about applience is sufficient.
            # when "reference"    then @text ""
            # when "unreference"  then @text "" 

          # Questions related entries
          # -------------------------

          when "Question" then switch entry.action

            # when "draft" then item
            #   icons   : [ "question-circle" ]
            #   url     : "/questions/#{entry.data._id}/drafts/#{entry._id}"
            #   body    : "#{entry.meta?.author?.name} wrote a new draft for a question."
            #   excerpt : entry.data.text
            #   time    : do entry._id.getTimestamp
            #   class   : "info"
            
            when "apply" 
              applied = entry.data._entry
              item 
                icons   : [ "plus-circle" ]
                url     : "/questions/#{applied.data._id}/"
                footer  : @cede =>
                  if applied.meta.author._id.equals entry.meta.author._id
                    @translate "%s published his own question",
                      applied.meta.author.name
                  else
                    @translate "%s approved a draft of a question by %s",
                      entry.meta.author.name,
                      applied.meta.author.name
                    
                body    : =>
                  @i class: "fa fa-fw text-muted fa-question-circle" 
                  @strong applied.data.text
                time    : do entry._id.getTimestamp
                class   : "success"
                    
            when "remove" then item
              icons   : [ "question-circle" ]
              url     : "/questions/#{entry.data._id}/"
              body    : "#{entry.meta?.author?.name} removed a question."
              excerpt : entry.data.text
              time    : do entry._id.getTimestamp
              class   : "danger"
            
            else item
              body    : "Something (#{entry.action}) happened to a question"
              url     : "/questions/#{entry.data._id}"
              time    : do entry._id.getTimestamp

          
          # Answers related entries
          # -------------------------

          when "Answer" 
            switch entry.action

              when "draft"
                if not entry.data.question
                  $ "Question (#{entry.populated "data.question"}) was apparently removed"
                  continue

                item
                  icons   : [ "puzzle-piece" ]
                  url     : "/questions/#{entry.data.question._id}/" +
                    "answers/#{entry.data._id}/" +
                    "drafts/#{entry._id}"
                  body    : "#{entry.meta?.author?.name} wrote a new draft for an answer."
                  excerpt : entry.data.question.text
                  time    : do entry._id.getTimestamp
                  class   : "info"
                
              when "apply" 
                applied   = entry.data._entry
                if not applied.data.question
                  $ "Question (#{applied.populated "data.question"}) was apparently removed"
                  continue

                item 
                  icons   : [ "puzzle-piece" ]
                  url     : "/questions/#{applied.data.question?._id}##{applied.data._id}/"
                  body    : =>
                    whose = if applied.meta.author._id.equals entry.meta.author._id
                      "his own draft"
                    else
                      " a draft by #{applied.meta.author.name}"
                      
                    @p "#{entry.meta?.author?.name} applied #{whose} to an answer"
                  excerpt : applied.data.question.text
                  time    : do entry._id.getTimestamp
                  class   : "success"

                      
              when "remove"
                if not entry.data.question
                  $ "Question (#{entry.populated "data.question"}) was apparently removed"
                  continue

                if not entry.data.author
                  $ "Author (participant #{entry.populated "data.author"}) was apparently removed"
                  continue

                item
                  icons   : [ "puzzle-piece" ]
                  url     : "/questions/#{entry.data.question}/answers/#{entry.data._id}"
                  body    : "#{entry.meta?.author?.name} removed an answer" # TODO: by #{entry.data.author}
                  excerpt : entry.data.text
                  time    : do entry._id.getTimestamp
                  class   : "danger"
              
              else item
                body    : "Something (#{entry.action}) happened to an answer"
                url     : "/questions/#{entry.data.question?._id}##{entry.data._id}"
                time    : do entry._id.getTimestamp

          # TODO: only in debug
          else item
            time    : do entry._id.getTimestamp

