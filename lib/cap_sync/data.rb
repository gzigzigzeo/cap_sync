# -*- encoding: utf-8 -*-

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do

_cset(:sync_folders, {"#{shared_path}/system" => "public/system"})
_cset(:sync_rsync_cmd, "rsync -rv --stats --delete --compress --skip-compress=jpg,gif,png,mp4")

# :sync for rsync, :cap for capistrano (used when rsync is not installed remotely)
_cset(:sync_method, :rsync)

namespace :sync do
  desc "Sync remote production data with local development machine"
  task :data do
    folders_to_sync = sync_folders
    
    if sync_method == :rsync
      folders_to_sync.each do |remote, local|
        host = find_servers(:roles => :web).first.host        
        system("#{sync_rsync_cmd} #{user}@#{host}:#{remote}/. #{local}")
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

end
