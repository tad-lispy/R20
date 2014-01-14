View      = require "teacup-view"

module.exports = new View
  components: __dirname
  (options = {}) ->

    {
      action
      method
      csrf
      answer
    } = options
    
    # TODO: This became redundant - method is always POST
    # The difference is in action: */answers or */answers/:single/drafts
    if method is "PUT"
      @p "Something better on your mind? Don't hesitate to share!"
    else
      @p "What's the correct answer?"


    @form
      method: "post"
      action: action
      =>
        @input
          type  : "hidden"
          name  : "_csrf"
          value : csrf
        # TODO: See above
        if options.method? then @input
          type  : "hidden"
          name  : "_method"
          value : method

        @div class: "form-group", =>
          @label for: "text", "What's the correct answer?", class: "sr-only"
          @textarea
            name        : "text"
            class       : "form-control"
            rows        : 8
            style       : "resize: none"
            placeholder : "Here goes some serious the legal knowledge..."
            answer?.text

        @div class: "form-group", =>
          @button
            type        : "submit"
            class       : "btn btn-primary"
            =>
              @i class: "icon-check-sign"
              @text " Ok"