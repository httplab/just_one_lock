# frozen_string_literal: true
require 'just_one_lock'
require 'tempfile'
require 'timeout'
require 'just_one_lock/locking_object'

describe JustOneLock::BlockingLocker do
  let(:locker) { JustOneLock::BlockingLocker.new }
  it_behaves_like 'a locking object'

  # Java doesn't support forking
  if RUBY_PLATFORM != 'java'
    it 'should work for multiple processes' do
      write('/tmp/number.txt', '0')

      parallel_forks(6) do
        number = File.read('/tmp/number.txt').to_i
        sleep(0.1)
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
      sleep(0.5)
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
