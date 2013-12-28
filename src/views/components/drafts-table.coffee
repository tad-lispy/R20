View      = require "teacup-view"
moment    = require "moment"
_         = require "lodash"
debug     = require "debug"

$         = debug   "R20:components:drafts-table"

module.exports = new View (options) ->
  { 
    drafts
    chosen
    applied
    root
  } = options
  console.dir drafts

  @table class: "table table-hover table-condensed table-striped", =>
    @tr =>
      @th => @span class: "sr-only", "state"
      @th "author"
      @th "time"

    for draft in drafts
      console.log "Draft"
      isChosen  = chosen?   and draft._id.equals chosen   
      isApplied = applied?  and draft._id.equals applied  
      if      isChosen  then  icon = "circle"
      else if isApplied then  icon = "ok-circle"
      else                    icon = "circle-blank"
      
      url     = root + draft.data._id + "/drafts/" + draft._id
      time    = moment(draft._id.getTimestamp()).fromNow()
      author  = draft.meta.author

      console.dir {
        draft: draft._id
        url
        time
        author
        chosen
        applied
      }

      @tr class: (if isChosen then "active" else if isApplied then "success"), =>

        @td =>
          @i class: "icon-li icon-" + icon
          @span class: "sr-only", (
            if isChosen then "chosen"
            else if isApplied then "applied"
          )

        @td =>
          if not isChosen then @a
            href: url
            author.name
          else @strong author.name

        @td =>
          if not isChosen then @a
            href: url
            time
          else @strong time
