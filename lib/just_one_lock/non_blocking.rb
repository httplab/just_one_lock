module JustOneLock::NonBlocking
  def self.filelock(
    lockname,
    delete_files: true,
    &block
  )
    result = nil

    File.open(lockname, File::RDWR|File::CREAT, 0644) do |f|
      if f.flock(File::LOCK_NB|File::LOCK_EX)
        result = JustOneLock.run(f, lockname, &block)
      else
        fail JustOneLock::AlreadyLocked
      end
    end

    JustOneLock.delete_unlocked_files if delete_files
    result
  end


  def self.prevent_multiple_executions(
    lock_dir,
    scope,
    output: JustOneLock::NullStream,
    delete_files: true,
    &block
  )
    scope_name = scope.gsub(':', '_')
    lock_path = File.join(lock_dir, scope_name + '.lock')

    begin
      return filelock(lock_path, delete_files: delete_files, &block)
    rescue JustOneLock::AlreadyLocked => e
      JustOneLock.already_locked(output, scope)
    end
  end
end


