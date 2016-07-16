# frozen_string_literal: true
class JustOneLock::NonBlockingLocker < JustOneLock::BaseLocker
  def lock(lock_path, &block)
    result = nil

    File.open(lock_path, File::RDWR | File::CREAT, 0o644) do |f|
      if f.flock(File::LOCK_NB | File::LOCK_EX)
        result = run(f, lock_path, &block)
      else
        raise JustOneLock::AlreadyLocked
      end
    end

    result
  end
end
