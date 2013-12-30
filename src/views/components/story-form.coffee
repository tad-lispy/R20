View      = require "teacup-view"
module.exports = new View
  components: __dirname
  (options = {}) ->

    {
      action
      method
      csrf
      story
    } = options

    @form
      method: "post"
      action: action
      =>
        @input
          type  : "hidden"
          name  : "_csrf"
          value : csrf

        if method? then @input
          type  : "hidden"
          name  : "_method"
          value : method

        @div class: "form-group", =>
          @label for: "text", "What's the story?", class: "sr-only"
          @textarea
            name        : "text"
            class       : "form-control"
            rows        : 8
            style       : "resize: none"
            placeholder : "Give us the facts, we will give you the law..."
            story?.text

        @div class: "form-group", =>
          @button
            type        : "submit"
            class       : "btn btn-primary"
            =>
              @i class: "icon-check-sign"
              @text " Ok"