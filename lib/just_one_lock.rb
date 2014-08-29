require 'just_one_lock/version'
require 'just_one_lock/blocking'
require 'just_one_lock/non_blocking'

module JustOneLock
  class AlreadyLocked < StandardError; end

  class NullStream
    class << self
      def puts(str); end
    end
  end

  @files = {}

  def self.delete_unlocked_files
    paths_to_delete = []

    @files.each do |path, f|
      if File.exists?(path) && f.closed?
        paths_to_delete << path
      end
    end

    paths_to_delete.each do |path|
      File.delete(path)
      @files.delete(path)
    end
  end

  def self.lock_paths
    @files.keys
  end

  def self.already_locked(output, scope)
    msg = "Another process <#{scope}> already is running"
    output.puts msg
    raise JustOneLock::AlreadyLocked, msg
  end

  private

  def self.write_pid(f)
    f.rewind
    f.write(Process.pid)
    f.flush
    f.truncate(f.pos)
  end

  def self.run(f, lockname, &block)
    @files[lockname] = f
    write_pid(f)
    block.call
  end
end
