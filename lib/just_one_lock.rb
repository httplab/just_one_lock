require 'just_one_lock/version'
require 'just_one_lock/world'
require 'just_one_lock/base_locker'
require 'just_one_lock/blocking_locker'
require 'just_one_lock/non_blocking_locker'
require 'forwardable'

module JustOneLock
  class AlreadyLocked < StandardError; end

  class << self
    extend ::Forwardable
    def_delegators :world, :before_lock, :after_lock, :delete_unlocked_files, :puts
  end

  def self.world
    @world ||= JustOneLock::World.new
  end

  def self.prevent_multiple_executions(
    scope,
    locker = JustOneLock::NonBlockingLocker.new,
    &block
  )
    scope_name = scope.gsub(':', '_')
    lock_path = File.join(world.directory, scope_name + '.lock')

    begin
      return locker.lock(lock_path, &block)
    rescue JustOneLock::AlreadyLocked => e
      locker.already_locked(scope)
    end
  end
end

