namespace :household do
  desc "Back up the SQLite database and receipt files"
  task backup: :environment do
    destination = Backup::Snapshot.call
    puts destination
  end

  desc "Restore a backup directory created by household:backup"
  task :restore, [ :directory ] => :environment do |_task, args|
    directory = args[:directory] || ENV.fetch("BACKUP_DIR")
    Backup::Snapshot.restore(directory)
    puts directory
  end
end
