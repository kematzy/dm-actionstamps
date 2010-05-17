
# Need to import datamapper and other gems
# require 'rubygems' # read [ http://gist.github.com/54177 ] to understand why this line is commented out
require 'pathname'

# Add all external dependencies for the plugin here
# gem 'dm-core', '~> 0.10.2'
require 'dm-core'

# Require plugin-files
require Pathname(__FILE__).dirname.expand_path / 'dm-actionstamps' / 'actionstamps.rb'

DataMapper::Model.append_extensions(DataMapper::Actionstamps)
# DataMapper::Model.append_inclusions(DataMapper::Actionstamps)


