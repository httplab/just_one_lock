require 'timeout'

class JustOneLock::BlockingLocker < JustOneLock::BaseLocker
  DEFAULT_TIMEOUT = 1

  attr_accessor :timeout

  def initialize(timeout: DEFAULT_TIMEOUT)
    @timeout = timeout
  end

  def lock(lock_path, &block)
    result = nil

    File.open(lock_path, File::RDWR|File::CREAT, 0644) do |f|
      Timeout::timeout(@timeout, JustOneLock::AlreadyLocked) { f.flock(File::LOCK_EX) }

      result = run(f, lock_path, &block)
    end

    result
  end
end

