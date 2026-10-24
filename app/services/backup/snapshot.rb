module Backup
  class Snapshot
    def self.call(root: backup_root)
      FileUtils.mkdir_p(root)
      destination = root.join("backup-#{Time.current.strftime("%Y%m%d%H%M%S")}")
      FileUtils.mkdir_p(destination)
      copy_database(destination.join("database.sqlite3"))
      copy_attachments(destination.join("storage"))
      prune(root)
      destination
    end

    def self.restore(backup_dir)
      database = Pathname(backup_dir).join("database.sqlite3")
      storage = Pathname(backup_dir).join("storage")
      raise ArgumentError, "Backup database is missing" unless database.exist?

      live = Pathname(ActiveRecord::Base.connection_db_config.database)
      ActiveRecord::Base.connection.disconnect!
      FileUtils.rm_f("#{live}-wal")
      FileUtils.rm_f("#{live}-shm")
      copy_sqlite(database, live)
      ActiveRecord::Base.establish_connection
      FileUtils.rm_rf(attachment_root)
      FileUtils.mkdir_p(attachment_root)
      FileUtils.cp_r("#{storage}/.", attachment_root) if storage.exist?
      backup_dir
    end

    def self.backup_root
      Pathname(ENV.fetch("BACKUP_ROOT") { Rails.root.join("tmp/backups") })
    end

    def self.copy_database(destination)
      copy_sqlite(Pathname(ActiveRecord::Base.connection_db_config.database), destination)
    end

    def self.copy_sqlite(source, destination)
      require "sqlite3"
      src = SQLite3::Database.new(source.to_s, readonly: true)
      dst = SQLite3::Database.new(destination.to_s)
      backup = SQLite3::Backup.new(dst, "main", src, "main")
      backup.step(-1)
      backup.finish
    ensure
      src&.close
      dst&.close
    end

    def self.copy_attachments(destination)
      FileUtils.mkdir_p(destination)
      return unless attachment_root.exist?

      FileUtils.cp_r("#{attachment_root}/.", destination)
    end

    def self.attachment_root
      Pathname(ActiveStorage::Blob.service.root)
    end

    def self.prune(root)
      keep = ENV.fetch("BACKUP_RETENTION", 30).to_i
      dirs = Pathname(root).children.select(&:directory?).sort
      dirs[0...-keep].each { |dir| FileUtils.rm_rf(dir) } if dirs.size > keep
    end
  end
end
