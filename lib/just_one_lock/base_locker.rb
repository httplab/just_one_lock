# frozen_string_literal: true
class JustOneLock::BaseLocker
  def already_locked(scope)
    msg = "Another process <#{scope}> already is running"
    JustOneLock.puts msg
    raise JustOneLock::AlreadyLocked, msg
  end

  private

  def write_pid(f)
    f.rewind
    f.write(Process.pid)
    f.flush
    f.truncate(f.pos)
  end

  def run(f, path)
    write_pid(f)

    JustOneLock.before_lock(path, f)
    result = yield
    JustOneLock.after_lock(path, f)

    result
  end
end
