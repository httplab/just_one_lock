require 'just_one_lock/version'
require 'timeout'

module JustOneLock
  DEFAULT_TIMEOUT = 0.01
  class AlreadyLocked < StandardError; end

  class NullStream
    class << self
      def puts(str); end
      def <<(o); self; end
    end
  end

  def self.filelock(lockname, timeout: JustOneLock::DEFAULT_TIMEOUT, &block)
    File.open(lockname, File::RDWR|File::CREAT, 0644) do |file|
      Timeout::timeout(timeout, JustOneLock::AlreadyLocked) { file.flock(File::LOCK_EX) }

      yield
    end
  end

  def self.prevent_multiple_executions(lock_dir, scope, output: JustOneLock::NullStream, timeout: JustOneLock::DEFAULT_TIMEOUT, &block)
    scope_name = scope.gsub(':', '_')
    lock_path = File.join(lock_dir, scope_name + '.lock')

    begin
      return filelock(lock_path, timeout: timeout, &block)
    rescue JustOneLock::AlreadyLocked => e
      output.puts "Another process <#{scope}> already is running"
    end
  end
end
