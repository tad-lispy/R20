{
  renderable, text
  ul, li,
  a, i, button, span
} = require "teacup"

module.exports = renderable (items) =>
  links =
    "show-drafts": (title) =>
      a 
        href: "#show-drafts"
        data:
          toggle: "modal"
          target: "#story-drafts-dialog"
        =>
          i class: "icon-folder-close"
          text " show drafts"
    "drop-story": =>
      a 
        href: "#drop-story"
        data:
          toggle: "modal"
          target: "#story-drop-dialog"
        =>
          i class: "icon-remove-sign"
          text " drop this story"

    "edit-story": =>
      a 
        href: "#edit-story"
        data:
          toggle: "modal"
          target: "#story-edit-dialog"
        =>
          i class: "icon-edit"
          text " make changes"


  button
    class : "btn btn-default  dropdown-toggle"
    data  :
      toggle: "dropdown"
    =>
      span class: "caret"
      span class: "sr-only", "Toggle dropdown"

  ul class: "dropdown-menu", role: "menu", =>
    (li => do links[item]) for item in items
