Meteor.startup ->
  resetDatabase() unless Tables.find().count() > 0

Meteor.publish "tables", ->
  Tables.find $or: [
    publicq: true
  ,
    owner: @userId
  ]

Meteor.publish "directory", ->
  Meteor.users.find {},
    fields:
      username: 1
      profile: 1

# example data taken from
# http://www.stat.cmu.edu/~gklein/discrete/OpeningExamples-2011.pdf
@resetDatabase = ->
  console.log "Resetting database!"
  Tables.remove {}
  sampleTables = [
    title: "gender and politics"
    description: "2000 General Social Survey"
    variables: ["gender", "party"]
    categories: [["female", "male"], ["Dem", "ind", "Rep"]]
    data: [762, 484, 327, 239, 468, 477]
    publicq: true
  ,
    title: "cold French skiers"
    description: "Linus Pauling"
    variables: ["intervention", "outcome"]
    categories: [["placebo", "vitamin C"], ["cold", "no cold"]]
    data: [31, 109, 17, 122]
    publicq: true
  ,
    title: "Wolf's dice data"
    description: "astronomer Rudolf Wolf http://bayes.wustl.edu/etj/articles/entropy.concentration.pdf"
    variables: ["red", "white"]
    categories: [["1", "2", "3", "4", "5", "6"], ["1", "2", "3", "4", "5", "6"]]
    data: [547, 587, 500, 462, 621, 690, 609, 655, 497, 535, 651, 684, 514, 540, 468, 438, 587, 629, 462, 507, 414, 413, 509, 611, 551, 562, 499, 506, 658, 672, 563, 598, 519, 487, 609, 646]
    publicq: true
  ]
  for t in sampleTables
    ContingencyTable.updateMargins t
    Tables.insert t
