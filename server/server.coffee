Meteor.startup ->
  resetDatabase() unless Tables.find().count() > 0

Meteor.publish "directory", ->
  Meteor.users.find {},
    fields:
      username: 1
      profile: 1

Meteor.publish "tables", ->
  if Roles.userIsInRole(@userId, ["admin"])
    Tables.find()
  else
    Tables.find $or: [
      publicq: true
    ,
      owner: @userId
    ]

# http://stackoverflow.com/questions/13857866/imagemagick-in-meteorjs-with-the-help-of-meteor-router-and-fibers
# http://d3export.cancan.cshl.edu/
Meteor.Router.add
  "/tables/:id.json": (id) ->
    # Tables.findOne id
    t = Tables.findOne id
    JSON.stringify t, ['title', 'description', 'variables', 'categories', 'data'], '\t'

# basic response
  "/tables/:id.csv": (id) ->
    t = Tables.findOne id
    ContingencyTable.tocsv t

# canonical response
  "/tables/:id.tsv": (id) ->
    response = this.response
    response.writeHead(200, {'Content-Type': 'text/tsv'});
    t = Tables.findOne id
    response.write(ContingencyTable.tocsv t, '\t')

# basic response
  "/tables/:id.svg": (id) ->
    t = Tables.findOne id
    t.svg

# example data taken from
# http://www.stat.cmu.edu/~gklein/discrete/OpeningExamples-2011.pdf
@resetDatabase = ->
  console.log "Resetting database!"
  Meteor.users.remove {}
  Tables.remove {}
  initialUsers = [
    email: "admin@example.com"
    password: "password"
    username: "admin"
    name: "Administrator"
    roles: ["admin"]
  ,
    email: "foo@example.com"
    password: "password"
    username: "foo"
    name: "Foo"
    roles: []
  ,
    email: "bar@example.com"
    password: "password"
    username: "bar"
    name: "Bar"
    roles: []
  ]
  for user in initialUsers
    userid = Accounts.createUser
      email: user.email
      password: user.password
      username: user.username
      profile:
        name: user.name
    if user.roles.length > 0
      Roles.addUsersToRoles userid, user.roles
  admin = Meteor.users.findOne
    username: "admin"
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
  ,
    title: "eye and hair color"
    description: "eye and hair color by sex"
    variables: ["sex", "eye", "hair"]
    categories: [["M", "F"], ["B", "G", "Z", "W"], ["K", "W", "R", "Y"]]
    data: [11, 50, 10, 30, 3, 15, 7, 8, 10, 25, 7, 5, 32, 53, 10, 3, 9, 34, 7, 64, 2, 14, 7, 8, 5, 29, 7, 5, 36, 66, 16, 4]
    publicq: true
  ]
  for t in sampleTables
    t.owner = admin._id
    ContingencyTable.updateMargins t
    Tables.insert t
