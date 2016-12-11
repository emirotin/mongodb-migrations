module.exports = (grunt) ->

  grunt.initConfig
    coffee:
      src:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'lib'
        ext: '.js'
        options: header: true
      bin:
        expand: true
        cwd: 'bin-src'
        src: ['**/*.coffee']
        dest: 'bin'
        ext: '.js'
        options: header: true

    concat:
      options:
        banner: '#!/usr/bin/env node\n\n'
      bin:
        src: ['bin/mm.js']
        dest: 'bin/mm'

    clean: ['bin/mm.js']

    watch:
      app:
        files: '**/*.coffee'
        tasks: ['default']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-clean'

  grunt.registerTask 'default', ['coffee', 'concat', 'clean']
