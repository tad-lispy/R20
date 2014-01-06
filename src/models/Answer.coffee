mongoose    = require "mongoose"

Question    = require "./Question"
Participant = require "./Participant"

Answer      = new mongoose.Schema
  text        :
    type        : String
    required    : yes
  author      :
    type        : mongoose.Schema.ObjectId
    ref         : 'Participant'
    required    : yes
  question    :
    type        : mongoose.Schema.ObjectId
    ref         : 'Question'
    required    : yes

module.exports = mongoose.model "Question", Question
