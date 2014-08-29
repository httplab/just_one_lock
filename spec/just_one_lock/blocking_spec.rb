require 'just_one_lock'
require 'tempfile'
require 'timeout'
require 'just_one_lock/locking_object'

describe JustOneLock::Blocking do
  it_behaves_like 'a locking object'

  def parallel(n = 2, lockpath: Tempfile.new(['sample', '.lock']).path, timeout: JustOneLock::Blocking::DEFAULT_TIMEOUT, &block)
    Timeout::timeout(5) do
      dir, scope = dir_and_scope(lockpath)
      (1..n).map do
        Thread.new do
          JustOneLock::Blocking.prevent_multiple_executions(dir, scope, timeout: timeout, delete_files: false, &block)
        end
      end.map(&:join)
    end

    JustOneLock.delete_unlocked_files
  end

  def parallel_forks(n = 2, lockpath: Tempfile.new(['sample', '.lock']).path, timeout: JustOneLock::Blocking::DEFAULT_TIMEOUT, &block)
    Timeout::timeout(5) do
      dir, scope = dir_and_scope(lockpath)

      (1..n).map do
        fork {
          JustOneLock::Blocking.prevent_multiple_executions(dir, scope, timeout: timeout, delete_files: false, &block)
        }
      end.map do |pid|
        Process.waitpid(pid)
      end
    end

    JustOneLock.delete_unlocked_files
  end

  # Java doesn't support forking
  if RUBY_PLATFORM != 'java'
    it 'should work for multiple processes' do
      write('/tmp/number.txt', '0')

      parallel_forks(6) do
        number = File.read('/tmp/number.txt').to_i
        sleep(JustOneLock::Blocking::DEFAULT_TIMEOUT / 100)
        write('/tmp/number.txt', (number + 7).to_s)
      end

      number = File.read('/tmp/number.txt').to_i

      expect(number).to eq(42)
    end

    it 'should handle heavy forking' do
      write('/tmp/number.txt', '0')

      FORKS_NUMBER = 100
      parallel_forks(FORKS_NUMBER) do
        number = File.read('/tmp/number.txt').to_i
        write('/tmp/number.txt', (number + 1).to_s)
      end

      number = File.read('/tmp/number.txt').to_i

      expect(number).to eq(FORKS_NUMBER)
    end
  end

  it 'runs in parallel without race condition' do
    answer = 0

    parallel(2) do
      value = answer
      sleep(JustOneLock::Blocking::DEFAULT_TIMEOUT / 2)
      answer = value + 21
    end

    expect(answer).to eq(42)
  end

  it 'handles high amount of concurrent tasks' do
    answer = 0

    parallel(100) do
      value = answer
      answer = value + 1
    end

    expect(answer).to eq(100)
  end
end

