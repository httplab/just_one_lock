def lock_dir
  '/tmp'
end

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
