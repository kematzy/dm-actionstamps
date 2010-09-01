
require 'rubygems'
require 'spec'
require 'pathname'
require Pathname(__FILE__).dirname.parent.expand_path + 'lib/dm-actionstamps'
require 'dm-core'
require 'dm-migrations'

def load_driver(name, default_uri)
  return false if ENV['ADAPTER'] != name.to_s
  
  lib = "dm-#{name}-adapter"
  
  begin
    gem lib, '>=1.0'
    require lib
    DataMapper.setup(name, ENV["#{name.to_s.upcase}_SPEC_URI"] || default_uri)
    DataMapper::Repository.adapters[:default] =  DataMapper::Repository.adapters[name]
    true
  rescue Gem::LoadError => e
    warn "Could not load #{lib}: #{e}"
    false
  end
end

ENV['ADAPTER'] ||= 'sqlite'

HAS_SQLITE3  = load_driver(:sqlite,  'sqlite3::memory:')
HAS_MYSQL    = load_driver(:mysql,    'mysql://localhost/dm_core_test')
HAS_POSTGRES = load_driver(:postgres, 'postgres://postgres@localhost/dm_core_test')
