{
  renderable, tag, text
  div, span
  i
  form, button, input
} = require "teacup"

module.exports = renderable ->
  form
    method: "get"
    =>
      div class: "input-group input-group-lg", =>
        input
          type        : "query"
          class       : "form-control"
          placeholder : "What seems to be the problem?"
          name        : "query"
          value       : @query
        span class: "input-group-btn", =>
          button
            class     : "btn btn-primary"
            type      : "submit"
            => i class: "icon-question-sign"
