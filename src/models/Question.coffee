# Question model

mongoose  = require "mongoose"

Story     = require "./Story"

Question  = new mongoose.Schema
  text      : 
    type      : String
    required  : yes
    unique    : yes

# # TODO: answers has to be in their own collection and to point to a question.
# Answer    = new mongoose.Schema
#   text      :
#     type      : String
#     required  : yes
#   author    :
#     type      : mongoose.Schema.ObjectId
#     ref       : 'Participant'
#     required  : yes

Question.methods.findStories = (conditions, callback) ->
  if (not callback) and typeof conditions is "function"
    callback = conditions
    conditions = {}

  conditions.questions = @._id

  Story.find conditions, callback

Question.methods.findAnswers = (conditions, callback) ->
  return callback null, []
  
  if (not callback) and typeof conditions is "function"
    callback = conditions
    conditions = {}

  conditions.question = @._id

  Answer.find conditions, callback

Question.plugin (require "./Journal"),
  omit:
    answers: true
  populate:
    path  : "meta.author"
    model : "Participant"


module.exports = mongoose.model 'Question', Question