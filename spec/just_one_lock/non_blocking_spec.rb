# frozen_string_literal: true
require 'just_one_lock'
require 'tempfile'
require 'timeout'
require 'just_one_lock/locking_object'

describe JustOneLock::NonBlockingLocker do
  let(:locker) { JustOneLock::NonBlockingLocker.new }
  it_behaves_like 'a locking object'
end
