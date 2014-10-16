class JustOneLock::World
  attr_accessor :output, :directory, :delete_files

  def initialize
    @files = {}
    @output = $stdout
    @directory = '/tmp'
    @delete_files = true
  end

  def delete_unlocked_files
    paths_to_delete = []

    @files.each do |path, f|
      if File.exists?(path) && f.closed?
        paths_to_delete << path
      end
    end

    paths_to_delete.each do |path|
      File.delete(path)
      @files.delete(path)
    end
  end

  def before_lock(name, file)
    @files[name] = file
  end

  def after_lock(name, file)
    delete_unlocked_files if delete_files
  end

  def lock_paths
    @files.keys
  end

  def puts(*args)
    output.puts(*args)
  end
end
