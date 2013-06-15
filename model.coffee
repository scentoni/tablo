# Each table is represented by a document in the Tables collection:
#   owner: user id
#   title, description: String
#   data: Array of Number
#   variables: Array of String
#   categories: Array of Array of String
#   publicq: Boolean
#   viewshares, editshares: Array of user id's that are shared

@Tables = new Meteor.Collection('tables')

Tables.allow
  insert: (userId, table) ->
    false # no cowboy inserts -- use createTable method

  update: (userId, table, fields, modifier) ->
    return false unless isModifiableByUserId(userId, table)
    allowed = ['title', 'description', 'data', 'variables', 'categories', 'publicq']
    return false if _.difference(fields, allowed).length # tried to write to forbidden field
    true

  remove: (userId, table) ->
    # You can only remove tables that you created, unless you are an admin
    @isModifiableByUserId(table, userId)

######################

@NonEmptyString = Match.Where (x) ->
  check x, String
  x.length isnt 0

Meteor.methods
  # options should include: title, description, data, publicq
  createTable: (options = {}) ->
    try
      check options, Match.ObjectIncluding
        title: NonEmptyString
        description: NonEmptyString
        publicq: Boolean
        variables: []
        data: [Number]
        variables: [NonEmptyString]
        categories: [[NonEmptyString]]
    catch e
      throw new Meteor.Error(400, 'Required parameter missing')
    throw new Meteor.Error(413, 'Title too long') if options.title.length > 100
    throw new Meteor.Error(413, 'Description too long') if options.description.length > 1000
    throw new Meteor.Error(403, 'You must be logged in') unless @userId
    Tables.insert
      owner: @userId
      data: options.data
      variables: options.variables
      categories: options.categories
      title: options.title
      description: options.description
      publicq: options.publicq

  updateTable: (options = {}) ->
    try
      check options, Match.ObjectIncluding
        _id: NonEmptyString
        owner: NonEmptyString
        title: NonEmptyString
        description: NonEmptyString
        publicq: Boolean
        variables: []
        data: [Number]
        variables: [NonEmptyString]
        categories: [[NonEmptyString]]
    catch e
      throw new Meteor.Error(400, 'Required parameter missing')
    throw new Meteor.Error(413, 'Title too long') if options.title.length > 100
    throw new Meteor.Error(413, 'Description too long') if options.description.length > 1000
    throw new Meteor.Error(403, 'You must be logged in') unless @userId
    Tables.update options._id,
      $set:
        data: options.data
        variables: options.variables
        categories: options.categories
        title: options.title
        description: options.description
        publicq: options.publicq

  resetDB: ->
    resetDatabase()

@displayTitle = (table) ->
  table.title

@lookupTableID = (table) ->
  table._id

@isModifiableByUserId = (userId, table) ->
  userId and (table.owner is userId or Roles.userIsInRole(userId, ['admin']))

@isModifiable = (table) ->
  isModifiableByUserId Meteor.user()?._id, table
