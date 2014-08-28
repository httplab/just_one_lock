require 'just_one_lock'
require 'tempfile'
require 'timeout'

describe JustOneLock do

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

  def parallel(n = 2, lockpath: Tempfile.new(['sample', '.lock']).path, timeout: JustOneLock::DEFAULT_TIMEOUT, &block)
    Timeout::timeout(5) do
      dir, scope = dir_and_scope(lockpath)
      (1..n).map do
        Thread.new do
          JustOneLock.prevent_multiple_executions(dir, scope, timeout: timeout, &block)
        end
      end.map(&:join)
    end
  end

  def parallel_forks(n = 2, lockpath: Tempfile.new(['sample', '.lock']).path, timeout: JustOneLock::DEFAULT_TIMEOUT, &block)
    Timeout::timeout(5) do
      dir, scope = dir_and_scope(lockpath)

      (1..n).map do
        fork {
          JustOneLock.prevent_multiple_executions(dir, scope, timeout: timeout, &block)
        }
      end.map do |pid|
        Process.waitpid(pid)
      end
    end
  end

  it 'runs simple ruby block as usual' do
    Dir.mktmpdir do |dir|
      lockpath = File.join(dir, 'sample.lock')
      answer = 0

      JustOneLock.filelock lockpath do
        answer += 42
      end

      expect(answer).to eq(42)
    end
  end

  it 'returns value returned by block' do
    Dir.mktmpdir do |dir|
      lockpath = File.join(dir, 'sample.lock')
      answer = 0

      answer = JustOneLock.filelock lockpath do
        42
      end

      expect(answer).to eq(42)
    end
  end

  it 'runs in parallel without race condition' do
    answer = 0

    parallel(2) do
      value = answer
      sleep(JustOneLock::DEFAULT_TIMEOUT / 2)
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

  it 'creates lock file on disk during block execution' do
    lockpath = Tempfile.new(['sample', '.lock']).path
    parallel(2, lockpath: lockpath) do
      expect(File.exist?(lockpath)).to eq(true)
    end
  end

  it 'runs in parallel without race condition' do
    lockpath = Tempfile.new(['sample', '.lock']).path

    answer = 0

    begin
      JustOneLock.filelock(lockpath) do
        raise '42'
      end
    rescue RuntimeError
    end

    JustOneLock.filelock(lockpath) do
      answer += 42
    end

    expect(answer).to eq(42)
  end

  it 'times out after specified number of seconds' do
    Dir.mktmpdir do |dir|
      lockpath = File.join(dir, 'sample.lock')

      answer = 42
      locked = false

      Thread.new do
        JustOneLock.filelock lockpath do
          locked = true
          sleep 20
        end
      end

      Timeout::timeout(1) do
        while locked == false
          sleep 0.1
        end
      end

      expect do
        JustOneLock.filelock lockpath, timeout: 0.001 do
          answer = 0
        end
      end.to raise_error(JustOneLock::AlreadyLocked)

      expect(answer).to eq(42)
    end
  end

  # Java doesn't support forking
  if RUBY_PLATFORM != 'java'

    it 'should work for multiple processes' do
      write('/tmp/number.txt', '0')

      parallel_forks(6) do
        number = File.read('/tmp/number.txt').to_i
        sleep(JustOneLock::DEFAULT_TIMEOUT / 100)
        write('/tmp/number.txt', (number + 7).to_s)
      end

      number = File.read('/tmp/number.txt').to_i

      expect(number).to eq(42)
    end

    it 'should handle heavy forking' do
      write('/tmp/number.txt', '0')

      FORKS_NUMBER = 100
      parallel_forks(FORKS_NUMBER, timeout: 1) do
        number = File.read('/tmp/number.txt').to_i
        write('/tmp/number.txt', (number + 1).to_s)
      end

      number = File.read('/tmp/number.txt').to_i

      expect(number).to eq(FORKS_NUMBER)
    end

    it 'should unblock files when killing processes' do
      lockpath = Tempfile.new(['sample', '.lock']).path
      dir, scope = dir_and_scope(lockpath)

      Dir.mktmpdir do |dir|
        pid = fork {
          JustOneLock.prevent_multiple_executions(dir, scope) do
            sleep 10
          end
        }

        Timeout::timeout(1) do
          while !File.exist?(lockpath)
            sleep 0.1
          end
        end

        answer = 0

        thread = Thread.new {
          JustOneLock.prevent_multiple_executions(dir, scope) do
            answer += 42
          end
        }

        expect(answer).to eq(0)
        Process.kill(9, pid)
        thread.join

        expect(answer).to eq(42)
      end
    end

    it 'should handle Pathname as well as string path' do
      Dir.mktmpdir do |dir|
        lockpath = Pathname.new(File.join(dir, 'sample.lock'))

        answer = 0
        JustOneLock.filelock lockpath do
          answer += 42
        end

        expect(answer).to eq(42)
      end
    end

  end

  # It failed for 1.8.7  (cannot convert to String)
  it 'works for Tempfile' do
    answer = 0

    JustOneLock.filelock Tempfile.new(['sample', '.lock']) do
      answer += 42
    end

    expect(answer).to eq(42)
  end

  # If implemented the wrong way lock is created elsewhere
  it 'creates file with exact path provided' do
    filename = "/tmp/awesome-lock-#{rand}.lock"

    JustOneLock.filelock filename do
    end

    expect(File.exist?(filename)).to eq(true)
  end
end
