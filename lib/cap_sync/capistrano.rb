# -*- encoding: utf-8 -*-

require 'fileutils'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do

_cset(:app_name) { abort('Set the application name before loading "cap_sync"') }

_cset(:sync_local_env, 'development')
_cset(:sync_remote_env, 'production')
_cset(:sync_local_load_cmd, 'mysql')
_cset(:sync_remote_dump_cmd, 'mysqldump')
_cset(:sync_local_tmp_path, 'tmp')
_cset(:sync_remote_tmp_path, "#{shared_path}/tmp")
_cset(:sync_local_keep_dumps, true)
_cset(:sync_remote_keep_dumps, false)
_cset(:sync_compress, true)
_cset(:sync_compress_cmd, 'gzip -c') # gzip -c #{dump} #{gzipped_dump}
_cset(:sync_uncompress_cmd, 'gunzip -c') # gunzip -c #{gzipped_dump} > #{dump}

namespace :sync do
  desc "Sync remote production database with local development database"
  task :db do
    # Get the dump of remote database
    username, password, database, host, port = remote_database_config(sync_remote_env)
    dump = "sync-#{Time.now.to_i}.sql"
    run "#{sync_remote_dump_cmd} -u #{username} --password=\"#{password}\" -h #{host} --port #{port} #{database} > #{sync_remote_tmp_path}/#{dump}"

    # Compress and download it
    if sync_compress
      run "#{sync_compress_cmd} #{sync_remote_tmp_path}/#{dump} > #{sync_remote_tmp_path}/#{dump}.gz"
      get "#{sync_remote_tmp_path}/#{dump}.gz", "#{sync_local_tmp_path}/#{dump}.gz"
      system("#{sync_uncompress_cmd} -c #{sync_local_tmp_path}/#{dump}.gz > #{sync_local_tmp_path}/#{dump}")
    else
      get "#{sync_remote_tmp_path}/#{dump}", "#{sync_local_tmp_path}/#{dump}"
    end

    # Load dump into local database
    username, password, database, host, port = local_database_config(sync_local_env)
    system("#{sync_local_load_cmd} #{database} -u#{username} --password=\"#{password}\" < #{sync_local_tmp_path}/#{dump}")

    # Remove temporary files
    unless sync_local_keep_dumps
      FileUtils.rm("#{sync_local_tmp_path}/#{dump}")
      FileUtils.rm("#{sync_local_tmp_path}/#{dump}.gz") if sync_compress
    else
      # If compression is on, keeps only gzipped dump
      FileUtils.rm("#{sync_local_tmp_path}/#{dump}") if sync_compress
    end

    unless sync_remote_keep_dumps
      run "rm #{sync_remote_tmp_path}/#{dump}"
      run "rm #{sync_remote_tmp_path}/#{dump}.gz" if sync_compress
    else
      run "rm #{sync_remote_tmp_path}/#{dump}" if sync_compress
    end
  end
end

end

def local_database_config(env)
  db = File.open("config/database.yml") { |yf| YAML::load(yf) }
  defaults_config(db[env.to_s])
end

def remote_database_config(env)
  remote_config = capture("cat #{current_path}/config/database.yml")
  db = YAML::load(remote_config)
  defaults_config(db[env.to_s])
end

def defaults_config(db)
  return db['username'], db['password'], db['database'], (db['host'] || '127.0.0.1'), (db['port'] || 3306)
end

#  {
#    :sync_folders => {"#{shared_path}/system" => "public/system"},  # Folders to sync remote => local
#    :rsync_cmd => "rsync",                                          # rsync command
#    :rsync_flags => "-rv --stats --delete",                         # rsync flags
#    :sync_method => :rsync                                          # :rsync or :cap
#  }.each do |var, value|
#    self.set(var, value) unless exists?(var)
#  end


#namespace :sync do
#  desc "Sync remote production data with local development machine"
#  task :data do
#    folders_to_sync = Hash[*ENV['FOLDERS'].split(',')] unless ENV['FOLDERS'].nil?
#    folders_to_sync ||= sync_folders
#    
#    if sync_method == :rsync
#      folders_to_sync.each do |remote, local|
#        host = find_servers(:roles => :web).first.host        
#        system("#{rsync_cmd} #{rsync_flags} #{user}@#{host}:#{remote}/. #{local}")
#      end
#    elsif sync_method == :cap
#      folders_to_sync.each do |remote, local|
#        ::FileUtils.rm_rf(local, :verbose => true)
#        download(remote, local, :recursive => true) do |event, downloader, *args|
#          case event
#          when :close then
#            puts "finished with #{args[0].remote}"
#          when :mkdir then
#            puts "creating directory #{args[0]}"
#          when :finish then
#            puts "all done!"
#          end
#        end
#      end
#    else
#      raise ArgumentError, "Unknown sync method: should be :cap or :sync"
#    end        
#  end
#end

