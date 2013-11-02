# Question model

mongoose  = require "mongoose"

Story     = require "./Story"

Question  = new mongoose.Schema
  text      : 
    type      : String
    required  : yes
    unique    : yes
  answers   : [ Answer ]

Answer    = new mongoose.Schema
  text      :
    type      : String
    required  : yes
  author    :
    type      : mongoose.Schema.ObjectId
    ref       : 'Participant'
    required  : yes

Question.methods.findStories = (callback) ->
  Story.find questions: @._id, callback

module.exports = mongoose.model 'Question', Question