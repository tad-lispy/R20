# Story model

mongoose  = require "mongoose"
_         = require "underscore"

Story = new mongoose.Schema
  text        : 
    type        : String
    required    : yes
  questions : [
    type      : mongoose.Schema.ObjectId
    ref       : 'Question'
  ]

Story.pre "validate", (done) ->
  @questions = _.unique @questions.map (oid) -> do oid.toString
  do done

module.exports = mongoose.model 'Story', Story