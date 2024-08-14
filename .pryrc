require 'interactive_editor'
require 'awesome_print'
require 'pry-nav'
Pry.config.editor = "vim"
Pry.commands.alias_command 'c', 'continue'
Pry.commands.alias_command 's', 'step'
Pry.commands.alias_command 'n', 'next'
