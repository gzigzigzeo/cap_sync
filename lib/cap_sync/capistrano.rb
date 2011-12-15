# -*- encoding: utf-8 -*-

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do

_cset(:app_name) { abort('Set the application name before loading "cap_sync"') }

end

require 'cap_sync/db'
require 'cap_sync/data'
