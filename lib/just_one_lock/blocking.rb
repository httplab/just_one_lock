require 'timeout'

module JustOneLock::Blocking
  DEFAULT_TIMEOUT = 1
  class AlreadyLocked < StandardError; end

  def self.filelock(
    lockname,
    timeout: JustOneLock::Blocking::DEFAULT_TIMEOUT,
    delete_files: true,
    &block
  )
    result = nil
    File.open(lockname, File::RDWR|File::CREAT, 0644) do |f|
      Timeout::timeout(timeout, JustOneLock::Blocking::AlreadyLocked) { f.flock(File::LOCK_EX) }

      result = JustOneLock.run(f, lockname, &block)
    end

    JustOneLock.delete_unlocked_files if delete_files
    result
  end

  def self.prevent_multiple_executions(
    lock_dir,
    scope,
    output: JustOneLock::NullStream,
    timeout: JustOneLock::Blocking::DEFAULT_TIMEOUT,
    delete_files: true,
    &block
  )
    scope_name = scope.gsub(':', '_')
    lock_path = File.join(lock_dir, scope_name + '.lock')

    begin
      return filelock(lock_path, timeout: timeout, delete_files: delete_files, &block)
    rescue JustOneLock::Blocking::AlreadyLocked => e
      output.puts "Another process <#{scope}> already is running"
    end
  end
end

