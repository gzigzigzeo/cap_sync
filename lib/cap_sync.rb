# -*- encoding: utf-8 -*-

require 'fileutils'

Capistrano::Configuration.instance(:must_exist).load do
  {
    :sync_local_env => 'development',      # Local environment key in database.yml
    :sync_remote_env => 'production',      # Remote environment key in database.yml
    :sync_remote_dump_cmd => 'mysqldump',  # Remote mysqldump command
    :sync_local_load_cmd => 'mysql',       # Local mysqldump command
    :sync_keep_dumps => false,             # Keep downloaded dump in app's tmp after syncing

    :sync_folders => {"#{shared_path}/system" => "public/system"},  # Folders to sync remote => local
    :rsync_cmd => "rsync",                                          # rsync command
    :rsync_flags => "-rv --stats --delete",                         # rsync flags
    :sync_method => :rsync                                          # :rsync or :cap
  }.each do |var, value|
    self.set(var, value) unless exists?(var)
  end

  namespace :sync do
    desc "Sync remote production database with local development machine"
    task :db do
      username, password, database, host, port = remote_database_config(sync_remote_env)

      temp = "sync-#{Time.now.to_i}.sql"
      run "#{sync_remote_dump_cmd} -u #{username} --password=\"#{password}\" -h #{host} --port #{port} #{database} > #{shared_path}/#{temp}"
      get "#{shared_path}/#{temp}", "tmp/#{temp}"

      username, password, database, host, port = local_database_config(sync_local_env)

      system("#{sync_local_load_cmd} #{database} -u#{username} --password=\"#{password}\" < tmp/#{temp}")
      FileUtils.rm("tmp/#{temp}") unless sync_keep_dumps
      run "rm #{shared_path}/#{temp}"
    end

    desc "Sync remote production data with local development machine"
    task :data do
      folders_to_sync = Hash[*ENV['FOLDERS'].split(',')] || sync_folders
      
      if sync_method == :rsync
        folders_to_sync.each do |remote, local|
          host = find_servers(:roles => :web).first.host        
          system("#{rsync_cmd} #{rsync_flags} #{user}@#{host}:#{remote}/. #{local}")
        end
      elsif sync_method == :cap
        folders_to_sync.each do |remote, local|
          ::FileUtils.rm_rf(local, :verbose => true)
          download(remote, local, :recursive => true) do |event, downloader, *args|
            case event
            when :close then
              puts "finished with #{args[0].remote}"
            when :mkdir then
              puts "creating directory #{args[0]}"
            when :finish then
              puts "all done!"
            end
          end
        end
      else
        raise ArgumentError, "Unknown sync method: should be :cap or :sync"
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
    return db['username'], db['password'], db['database'], db['host'], (db['port'] || 3306)
  end
end