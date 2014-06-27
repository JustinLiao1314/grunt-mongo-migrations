module.exports = (grunt) ->
  migrate = ->
    require 'coffee-errors'
    Migrate = require '../mongo_migrate'

    grunt.config.requires 'migrations.path'
    grunt.config.requires 'migrations.mongo'

    class GruntMigrate extends Migrate
      log: -> grunt.log.ok arguments...
      error: -> grunt.fail.fatal arguments...

    new GruntMigrate grunt.config 'migrations'

  err = (fn) ->
    (err, args...) ->
      throw err if err?
      fn args...

  getName = ->
    {name} = grunt.cli.options
    return grunt.fail.fatal "Migration name must be specified with `#{"--name".bold}`" unless name?
    name

  grunt.registerTask 'migrate:generate', 'Create a new migration', ->
    done = @async()

    migrate().generate getName(), err (filename) ->
      grunt.log.ok "Created `#{filename.blue}`"
      done()

  grunt.registerTask 'migrate:one', 'Run a migration.', ->
    done = @async()
    name = getName()

    migrate().one name, err ->
      grunt.log.ok "Migrated `#{name.blue}`"
      done()

  grunt.registerTask 'migrate:test', 'Tests a migration.', ->
    done = @async()
    name = getName()

    migrate().test name, err ->
      grunt.log.ok "Completed `#{name.blue}`"
      done()

  grunt.registerTask 'migrate:down', 'Revert the most recent migration', ->
    done = @async()

    migrate().down err ->
      grunt.log.ok 'Migrated down'
      done err

  grunt.registerTask 'migrate:pending', 'List all pending migrations', ->
    done = @async()
    migrate = migrate()

    migrate.pending err (pending) ->
      grunt.log.ok 'No pending migrations' if pending.length == 0

      pending.forEach (name) ->
        grunt.log.ok "`#{name.blue}` is pending " + (migrate.get(name).requiresDowntime and "(requires downtime)".red.bold or '')

      done()

  grunt.registerTask 'migrate:all', 'Run all pending migrations', ->
    done = @async()

    migrate().all err ->
      grunt.log.ok 'Finished migrations'
      done()
