{
  renderable, tag, text
  div, span
  h3, h4, p
  a, i
} = require "teacup"

module.exports = renderable ->
  h3 class: "text-muted", "That may be of interest to you:"
  div class: "list-group", =>
    console.dir @search
    for result in @search.results
      a href: result.url, class: "list-group-item", =>
        h4 class: "list-group-item-heading", result.title
        p class: "list-group-item-text", "Lorem ipsum Donec id elit non mi porta gravida at eget metus. Maecenas sed diam eget risus varius blandit."

    a href: "/story/", class: "list-group-item active", =>
      h4 class: "list-group-item-heading", "Tell us your stroy."
      p class: "list-group-item-text", "If above topics didn't exhaust your problem, then share your story with us. We will try to help."