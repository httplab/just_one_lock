class JustOneLock::NonBlockingLocker < JustOneLock::BaseLocker
  def lock(lock_path, &block)
    result = nil

    File.open(lock_path, File::RDWR|File::CREAT, 0644) do |f|
      if f.flock(File::LOCK_NB|File::LOCK_EX)
        result = run(f, lock_path, &block)
      else
        fail JustOneLock::AlreadyLocked
      end
    end

    result
  end
end

