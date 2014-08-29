require 'just_one_lock'
require 'tempfile'
require 'timeout'
require 'just_one_lock/locking_object'

describe JustOneLock::NonBlocking do
  it_behaves_like 'a locking object'

  def parallel(n = 2, lockpath: Tempfile.new(['sample', '.lock']).path, &block)
    Timeout::timeout(5) do
      dir, scope = dir_and_scope(lockpath)
      (1..n).map do
        Thread.new do
          JustOneLock::Blocking.prevent_multiple_executions(dir, scope, delete_files: false, &block)
        end
      end.map(&:join)
    end

    JustOneLock.delete_unlocked_files
  end

  def parallel_forks(n = 2, lockpath: Tempfile.new(['sample', '.lock']).path, &block)
    Timeout::timeout(5) do
      dir, scope = dir_and_scope(lockpath)

      (1..n).map do
        fork {
          JustOneLock::Blocking.prevent_multiple_executions(dir, scope, delete_files: false, &block)
        }
      end.map do |pid|
        Process.waitpid(pid)
      end
    end

    JustOneLock.delete_unlocked_files
  end
end

