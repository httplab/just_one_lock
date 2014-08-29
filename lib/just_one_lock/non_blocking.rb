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
      end
    end

    JustOneLock.delete_unlocked_files if delete_files
    result
  end


  def self.prevent_multiple_executions(
    lock_dir,
    scope,
    output: JustOneLock::NullStream,
    &block
  )
    scope_name = scope.gsub(':', '_')
    lock_path = File.join(lock_dir, scope_name + '.lock')

    was_executed = filelock(lock_path, &block)

    unless was_executed
      output.puts "Another process <#{scope}> already is running"
    end
  end
end


