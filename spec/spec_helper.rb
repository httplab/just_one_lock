# Helper because File.write won't work for older Ruby
def write(filename, contents)
  File.open(filename.to_s, 'w') { |f| f.write(contents) }
end

def dir_and_scope(lockpath)
  path_segments = lockpath.split('/')
  scope = path_segments.last
  path_segments.delete scope
  dir = path_segments.join('/')
  [dir, scope]
end

def parallel(n = 2, lockpath: Tempfile.new(['sample', '.lock']).path, &block)
  Timeout::timeout(5) do
    dir, scope = dir_and_scope(lockpath)
    JustOneLock.world.directory = dir

    (1..n).map do
      Thread.new do
        JustOneLock::prevent_multiple_executions(scope, locker, &block)
      end
    end.map(&:join)
  end

  JustOneLock.delete_unlocked_files
end

def parallel_forks(n = 2, lockpath: Tempfile.new(['sample', '.lock']).path, &block)
  Timeout::timeout(5) do
    dir, scope = dir_and_scope(lockpath)
    JustOneLock.world.directory = dir

    (1..n).map do
      fork {
        JustOneLock::prevent_multiple_executions(scope, locker, &block)
      }
    end.map do |pid|
      Process.waitpid(pid)
    end
  end

  JustOneLock.delete_unlocked_files
end

JustOneLock.world.delete_files = false
