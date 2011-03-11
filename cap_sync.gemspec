# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "cap_sync"
  s.version     = '0.0.1'
  s.platform    = Gem::Platform::RUBY
  s.author      = "Victor Sokolov"
  s.email       = "gzigzigzeo@gmail.com"
  s.homepage    = "http://github.com/gzigzigzeo/cap_sync"
  s.summary     = %q{Capistrano recipe to sync database & files to your development machine from production server}
  s.description = %q{Capistrano recipe to sync database & files to your development machine from production server}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_path  = 'lib'
end