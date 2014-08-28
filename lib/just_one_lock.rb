require 'just_one_lock/version'
require 'timeout'

module JustOneLock
  class AlreadyLocked < StandardError; end

  def self.filelock(lockname, options = {}, &block)
    File.open(lockname, File::RDWR|File::CREAT, 0644) do |file|
      begin
        Timeout::timeout(options.fetch(:timeout, 60)) { file.flock(File::LOCK_EX) }
      rescue Timeout::Error => e
        raise JustOneLock::AlreadyLocked
      end

      yield
    end
  end

  def self.prevent_multiple_executions(lock_dir, scope, &block)
    scope_name = scope.gsub(':', '_')
    lock_path = File.join(lock_dir, scope_name + '.lock')

    begin
      return filelock(lock_path, &block)
    rescue JustOneLock::AlreadyLocked => e
      puts "Another process <#{scope}> already is running"
      exit(1)
    end
  end
end
