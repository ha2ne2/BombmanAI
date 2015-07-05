class Path
  attr_accessor :value, :prev, :f, :g, :h
  def initialize(value: nil, g: 0, h: 0, prev: nil)
    @value = value
    @g = g
    @h = h
    @f = g + h
    @prev = prev
  end
 
  def ==(path)
    @value == path.value
  end
 
  def inspect
    [@value, @g, @h, @f]
  end
end
 
def better_path? (path1,path2)
  path1.f < path2.f
end
 
def astar(open_list,close_list,goal_p,successor,cost_fn)
  if (open_list.empty?)
    nil
  else
    path = open_list.sort_by!(&:f).shift
    close_list.push(path)
    if (goal_p.(path.value))
      path
    else
      close_list.push(path)
      if path.g < 30
        successor.(path.value).each{ |val|
        path2 = Path.new(value: val, g: path.g+1, h: cost_fn.(val),
                         prev: path)
        old = nil
        if (old = open_list.find{|old| old == path2})
          if (better_path?(path2,old))
            open_list.delete(old)
            open_list.push(path2)
          end
        elsif (old = close_list.find{|old| old == path2})
          if (better_path?(path2,old))
            close_list.delete(old)
            open_list.push(path2)
          end
        else
          open_list.push(path2)
        end
        }
      end
      astar(open_list,close_list,goal_p,successor,cost_fn)
    end
  end
end
 
def path_to_list(path)
  if path.nil?
    return []
  end
  result = []
  rec = ->(path){
    result.push(path.value)
    if (path.prev)
      rec.(path.prev)
    end
  }
  rec.(path)
  result.reverse
end
