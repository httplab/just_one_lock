require 'spec_helper'

shared_examples 'a locking object' do
  it 'runs simple ruby block as usual' do
    Dir.mktmpdir do |lock_dir|
      lockpath = File.join(lock_dir, 'sample.lock')
      answer = 0

      locker.lock lockpath do
        answer += 42
      end

      expect(answer).to eq(42)
    end
  end

  it 'returns value returned by block' do
    Dir.mktmpdir do |lock_dir|
      lockpath = File.join(lock_dir, 'sample.lock')
      answer = 0

      answer = locker.lock lockpath do
        42
      end

      expect(answer).to eq(42)
    end
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
      locker.lock(lockpath) do
        raise '42'
      end
    rescue RuntimeError
    end

    locker.lock(lockpath) do
      answer += 42
    end

    expect(answer).to eq(42)
  end

  it 'times out after specified number of seconds' do
    Dir.mktmpdir do |lock_dir|
      lockpath = File.join(lock_dir, 'sample.lock')

      answer = 42
      locked = false

      Thread.new do
        locker.lock lockpath do
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
        locker.lock lockpath do
          answer = 0
        end
      end.to raise_error(JustOneLock::AlreadyLocked)

      expect(answer).to eq(42)
    end
  end

  # Java doesn't support forking
  if RUBY_PLATFORM != 'java'

    it 'should unblock files when killing processes' do
      lockpath = Tempfile.new(['sample', '.lock']).path
      dir, scope = dir_and_scope(lockpath)

      pid = fork {
        JustOneLock::prevent_multiple_executions(locker, scope) do
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
        JustOneLock::prevent_multiple_executions(locker, scope) do
          answer += 42
        end
      }

      expect(answer).to eq(0)
      Process.kill(9, pid)
      thread.join

      expect(answer).to eq(42)
    end

    it 'should handle Pathname as well as string path' do
      Dir.mktmpdir do |lock_dir|
        lockpath = Pathname.new(File.join(lock_dir, 'sample.lock'))

        answer = 0
        locker.lock lockpath do
          answer += 42
        end

        expect(answer).to eq(42)
      end
    end
  end

  # It failed for 1.8.7  (cannot convert to String)
  it 'works for Tempfile' do
    answer = 0

    locker.lock Tempfile.new(['sample', '.lock']) do
      answer += 42
    end

    expect(answer).to eq(42)
  end

  # If implemented the wrong way lock is created elsewhere
  it 'creates file with exact path provided' do
    filename = "/tmp/awesome-lock-#{rand}.lock"

    locker.lock filename do
    end

    expect(File.exist?(filename)).to eq(true)
  end
end


