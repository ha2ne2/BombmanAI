# coding: utf-8
require 'json'
require File.dirname(__FILE__) + '/path_finding.rb'

STDIN .set_encoding("UTF-8", "UTF-8")
STDOUT.set_encoding("UTF-8", "UTF-8")
STDERR.set_encoding("UTF-8", "UTF-8")

class Hoge
  def write(*x)
  end
  def print(*x)
  end
  def puts(*x)
  end
end

$stderr = Hoge.new()

def game_loop()
  $bomb_set_timer = 0
  $goal = nil
  puts "発"
  STDOUT.flush
  id = readline().to_i
  loop{
    data = JSON.parse(readline())
    print action2(data,id) + "\n"
    STDOUT.flush
  }
end

$bomb = nil
$goal = nil

FALLING_WALL = [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1], [7, 1], [8, 1], [9, 1], [10, 1], [11, 1], [12, 1], [13, 1], [13, 2], [13, 3], [13, 4], [13, 5], [13, 6], [13, 7], [13, 8], [13, 9], [13, 10], [13, 11], [13, 12], [13, 13], [12, 13], [11, 13], [10, 13], [9, 13], [8, 13], [7, 13], [6, 13], [5, 13], [4, 13], [3, 13], [2, 13], [1, 13], [1, 12], [1, 11], [1, 10], [1, 9], [1, 8], [1, 7], [1, 6], [1, 5], [1, 4], [1, 3], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [8, 2], [9, 2], [10, 2], [11, 2], [12, 2], [12, 3], [12, 4], [12, 5], [12, 6], [12, 7], [12, 8], [12, 9], [12, 10], [12, 11], [12, 12], [11, 12], [10, 12], [9, 12], [8, 12], [7, 12], [6, 12], [5, 12], [4, 12], [3, 12], [2, 12], [2, 11], [2, 10], [2, 9], [2, 8], [2, 7], [2, 6], [2, 5], [2, 4], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3], [7, 3], [8, 3], [9, 3], [10, 3], [11, 3], [11, 4], [11, 5], [11, 6], [11, 7], [11, 8], [11, 9], [11, 10], [11, 11], [10, 11], [9, 11], [8, 11], [7, 11], [6, 11], [5, 11], [4, 11], [3, 11], [3, 10], [3, 9], [3, 8], [3, 7], [3, 6], [3, 5], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4], [8, 4], [9, 4], [10, 4], [10, 5], [10, 6], [10, 7], [10, 8], [10, 9], [10, 10], [9, 10], [8, 10], [7, 10], [6, 10], [5, 10], [4, 10], [4, 9], [4, 8], [4, 7], [4, 6], [4, 5]]
FALLING_START = 360

def deep_copy(obj)
  Marshal.load(Marshal.dump(obj))
end

def update(world)
  next_world = deep_copy(world)

  next_world["turn"] += 1

  if (next_world["turn"] >= 360)
    i = next_world["turn"] - 360
    if (i < FALLING_WALL.length) 
         pos_ary = [FALLING_WALL[i][0],FALLING_WALL[i][1]]
         pos = pos(*pos_ary)
         next_world["walls"] += [pos_ary]
         next_world["blocks"].reject!{|x| x == pos_ary}
         next_world["items"].reject!{|item| item["pos"] == pos}
         next_world["bombs"].reject!{|bomb| bomb["pos"] == pos}
    end
  end
  
  next_world["bombs"].each{|bomb|
    bomb["timer"] -= 1
  }

  fires = chainly_explode(next_world)

  next_world["bombs"].reject!{|bomb|
    fires.include? bomb["pos"]
  }
  next_world["blocks"].reject!{|block|
    fires.include? pos(*block)
  }

  next_world["fires"] = fires.map{|pos|
    [pos["x"],pos["y"]]
  }
  
  next_world
end

def world_to_s(world)
  ary = Array.new(15){ Array.new(15,"　") }
  world["walls"].each{|w|
    ary[w[1]][w[0]] = "■"
  }
  world["blocks"].each{|b|
    ary[b[1]][b[0]] = "□"
  }

  world["bombs"].each{|b|
    ary[b["pos"]["y"]][b["pos"]["x"]] = "●"
  }

  world["fires"].each{|b|
    ary[b[1]][b[0]] = "火"
  }

  ary.map(&:join).join("\n")
end

def chainly_explode(world) #->[pos]
  bombs = world["bombs"]#.map(&:dup)
  fires = []
  exploding_bombs = bombs.select{|bomb|
    bomb["timer"] == 0
  }

  while (exploding_bombs.empty?.!)
    fires += exploding_bombs.map{|bomb| explode(world,bomb)}.flatten
    fires = fires.uniq
    bombs -= exploding_bombs
    exploding_bombs = bombs.select{|bomb|
      fires.include?(bomb["pos"])
    }
  end
  
  fires
end
      
def successor1((pos,world))
  next_world = update(world)
  movable_neighbours(world,pos)
    .select{|pos| not(fire?(next_world,pos)) && not(wall?(next_world,pos))}
    .map{|pos| [pos,next_world]}
end      


(def make_pipe(head,tail) [head,tail] end)
(def head(pipe) pipe[0] end)
(def tail(pipe) pipe[1].kind_of?(Proc) ? pipe[1] = pipe[1].call : pipe[1] end)
(def butlast(ary) (ary.first ary.size-1) end)
(def my_succ(n) n+1 end)
(def pipe_to_array(pipe) (butlast pipe.flatten) end)
(def iterate(f,x) [x, ->{iterate f, (f.call x)}] end)

def take(count, pipe, result: pipe)
  ((pipe == nil) or (count == 1)) ?
    pipe_to_array(result) :
    take(count-1, (tail pipe), result: result)
end

def compose(f,g)
  ->(x){f.(g.(x))}
end

def compose_n(n,f)
  if n == 0
    ->(x){x}
  else
    ([f]*n).reduce(&method(:compose))
  end
end

# 詰んでるかどうか。
def must_die_p(world,pos)
  worlds = take(11,iterate(method(:update),world))
  reachables = [pos]
  worlds.each{|world|
    $stderr.print(reachables.map{|pos|[pos["x"],pos["y"]]}," ",world["fires"],"\n")
    if (reachables.map{|pos|[pos["x"],pos["y"]]} - world["fires"]).empty?
      return true
    end
    reachables = reachables.flat_map{|pos|
      movable_neighbours(world,pos)
    }.uniq
  }
    
  return false
end
  
# 場所（そこへの移動途中で死なずに到達できる）を返す関数
def new_goal(world,player)
  $stderr.puts("find new_goal")
  reachables = reachable_places(world,player["pos"],10)

  item_poss = world["items"].select{|item|
    reachables.include? item["pos"]
  }.map{|item|
    item["pos"]
  }

  cands = reachables.shuffle
  cands = item_poss + (cands - item_poss)
  
  cands.each{|cand|
    $stderr.print("cand: ", cand, "\n")

    # 目的地がそこへ最短経路で行っても壁になる場所ならスキップ
    dist = manhattan_distance(player["pos"],cand)
    n_turn_later = compose_n(dist,method(:update))
    if(wall?(n_turn_later.(world),cand))
      next
    end
    
    path_list = path_to_goal2(world,player["pos"],cand)
    if path_list.empty?.!
      #path_list.lengthが1になる。
      needed_turn = path_list.length == 1 ? 1 : path_list.length-1
      if (must_die_p(compose_n(needed_turn,method(:update)).(world),
                     cand))
        next
      else
        return cand
      end
    end
  }
  nil
end

$goal = nil

def new_bomb(player)
  {"pos"=>{"x"=>player["pos"]["x"],
           "y"=>player["pos"]["y"]},
   "timer"=>10,
   "power"=>player["power"]}
end

def set_bomb(world,player)
  new_world = deep_copy(world)
  new_world["bombs"] += [new_bomb(player)]
  new_world
end

def action2(world,id)
  me = find_me(world,id)
  path_list = nil
  
  $stderr.print("GOAL: ",$goal,"\n")
  $stderr.print("POS: ",me["pos"],"\n")
  set_bomb_flag = false

  if rand(4) == 0
    world_set_bomb = set_bomb(world,me)
    goal = new_goal(world_set_bomb,me)
    if goal
      $goal = goal
      set_bomb_flag = true
    end
  end

  if $goal.nil? ||
     bomb?(world,$goal) ||
     wall?(world,$goal) || # このケースはいらない感じがするが
     $goal == me["pos"] ||
    (path_list = path_to_goal2(world,me["pos"],$goal)).empty?
  then

    if set_bomb_flag.!
      $goal = new_goal(world,me)
      if $goal.nil?
        return "STAY,FALSE"
      end
    end
  end
  
  path_list = path_to_goal2(world,me["pos"],$goal)
  $stderr.print("PATH: ",path_list.map{|x| x[0]},"\n")
  next_pos = (path_list[1] && path_list[1][0]) || me["pos"]
  action = to_command(me["pos"],next_pos) + "," + set_bomb_flag.to_s
  action
end  

def pos(x,y)
  {"x"=>x,"y"=>y}
end

def to_command (origin, dest) 
  #p [:origin,origin,:dest,dest]
  d = pos(dest["x"]-origin["x"],dest["y"]-origin["y"])
  if (d == pos(0,1))
    "DOWN"
  elsif (d == pos(0,-1))
    "UP"
  elsif (d == pos(-1,0))
     "LEFT"
  elsif (d == pos(1,0))
     "RIGHT"
  else
    "STAY"
  end
end


def manhattan_distance (p1,p2)
  (p1["x"]-p2["x"]).abs + (p1["y"]-p2["y"]).abs
end

def movable_neighbours(data,pos)
  [pos]+neighbours(pos).select{|p| movable?(data,p)}
end

# 目的地へ死なずに到達する経路を返す。
def path_to_goal2(world,start,goal)
  goal_p = ->((pos,world)){ goal == pos }
  successor = method(:successor1)
  cost_fn = ->((pos,world)){manhattan_distance(goal,pos)}
  start_path = Path.new(value: [start, world], g: 0, h: cost_fn.([start, world]), prev: nil)
  path = astar([start_path],[],goal_p,successor,cost_fn)
  path_to_list(path)
end

def path_to_goal(data,start,goal)
  goal_p = ->(pos){goal == pos}
  successor = method(:movable_neighbours).to_proc.curry.(data)
  cost_fn = method(:manhattan_distance).to_proc.curry.(goal)
  start_path = Path.new(value: start, g: 0, h: cost_fn.(start), prev: nil)
  path = astar([start_path],[],goal_p,successor,cost_fn)
  path_to_list(path)
end

def reachable_places(data,pos,n) # -> [pos]
  visited = []
  visitedp = ->(p){ visited.find{|p2| p["x"] == p2["x"] && p["y"] == p2["y"]}}
  rec = ->(pos,n){
    visited.push(pos)
    if (n != 0)
      nexts = neighbours(pos).select{|p| movable?(data,p) && !visitedp.(p)}
      nexts.each{|p| rec.(p,n-1)}
      nil
    end
  }
  rec.(pos,n)
  visited
end

def explode(data,bom)
  rec = -> (dir,p) {
    if (p <= bom["power"])
         tmp_pos =
           (dir == "up")? pos(bom["pos"]["x"],bom["pos"]["y"]-p):
           (dir == "down")? {"x"=>bom["pos"]["x"],"y"=>bom["pos"]["y"]+p}:
           (dir == "left")? {"x"=>bom["pos"]["x"]-p,"y"=>bom["pos"]["y"]}:
           {"x"=>bom["pos"]["x"]+p,"y"=>bom["pos"]["y"]}
         (block?(data,tmp_pos)#  ||
          # item?(data,tmp_pos)
         )? [tmp_pos]:
         (wall?(data,tmp_pos))? []:
         [tmp_pos] + rec.(dir,p+1)
    else
      []
    end
  }
  [[bom["pos"]],rec.("up",1),rec.("down",1),rec.("left",1),rec.("right",1)].flatten
end

def find_me(data,id)
  data["players"].find{|p|
    p["id"] == id
  }
end

def neighbours (pos)
  [[0,-1],[0,1],[-1,0],[1,0]].map{|dx,dy|
    pos(pos["x"]+dx,pos["y"]+dy)
  }
end

def movable? (data,pos) 
  not(wall?(data,pos) || block?(data,pos) || bomb?(data,pos))
end

def fire?(world,pos)
  world["fires"].any?{|p|
    p[0] == pos["x"] && p[1] == pos["y"]
  }
end

def wall? (data,pos)
  data["walls"].any?{|w|
    w[0] == pos["x"] && w[1] == pos["y"]
  }
end

def block?(data,pos)
  data["blocks"].any?{|b|
    b[0] == pos["x"] && b[1] == pos["y"]
  }
end

def bomb?(data,pos)
  data["bombs"].any?{|b|
    b["pos"]['x'] == pos["x"] && b["pos"]['y'] == pos["y"]
  }
end


def debug()
  id = 2
  world = JSON.parse('{"turn":432,"walls":[[0,0],[0,1],[0,2],[0,3],[0,4],[0,5],[0,6],[0,7],[0,8],[0,9],[0,10],[0,11],[0,12],[0,13],[0,14],[1,0],[1,14],[2,0],[2,2],[2,4],[2,6],[2,8],[2,10],[2,12],[2,14],[3,0],[3,14],[4,0],[4,2],[4,4],[4,6],[4,8],[4,10],[4,12],[4,14],[5,0],[5,14],[6,0],[6,2],[6,4],[6,6],[6,8],[6,10],[6,12],[6,14],[7,0],[7,14],[8,0],[8,2],[8,4],[8,6],[8,8],[8,10],[8,12],[8,14],[9,0],[9,14],[10,0],[10,2],[10,4],[10,6],[10,8],[10,10],[10,12],[10,14],[11,0],[11,14],[12,0],[12,2],[12,4],[12,6],[12,8],[12,10],[12,12],[12,14],[13,0],[13,14],[14,0],[14,1],[14,2],[14,3],[14,4],[14,5],[14,6],[14,7],[14,8],[14,9],[14,10],[14,11],[14,12],[14,13],[14,14],[1,1],[2,1],[3,1],[4,1],[5,1],[6,1],[7,1],[8,1],[9,1],[10,1],[11,1],[12,1],[13,1],[13,2],[13,3],[13,4],[13,5],[13,6],[13,7],[13,8],[13,9],[13,10],[13,11],[13,12],[13,13],[12,13],[11,13],[10,13],[9,13],[8,13],[7,13],[6,13],[5,13],[4,13],[3,13],[2,13],[1,13],[1,12],[1,11],[1,10],[1,9],[1,8],[1,7],[1,6],[1,5],[1,4],[1,3],[1,2],[2,2],[3,2],[4,2],[5,2],[6,2],[7,2],[8,2],[9,2],[10,2],[11,2],[12,2],[12,3],[12,4],[12,5],[12,6],[12,7],[12,8],[12,9],[12,10],[12,11],[12,12],[11,12],[10,12],[9,12],[8,12]],"blocks":[],"players":[{"name":"ハツネツAI","pos":{"x":9,"y":5},"power":2,"setBombLimit":2,"ch":"ハ","isAlive":true,"setBombCount":1,"totalSetBombCount":24,"id":0},{"name":"ハツ ネツAI","pos":{"x":7,"y":9},"power":2,"setBombLimit":2,"ch":"墓","isAlive":false,"setBombCount":0,"totalSetBombCount":1,"id":1},{"name":"発","pos":{"x":10,"y":9},"power":2,"setBombLimit":2,"ch":"発","isAlive":true,"setBombCount":0,"totalSetBombCount":0,"id":2},{"name":"ハツネツAI","pos":{"x":3,"y":7},"power":2,"setBombLimit":2,"ch":"墓","isAlive":false,"setBombCount":0,"totalSetBombCount":1,"id":3}],"bombs":[{"pos":{"x":9,"y":3},"timer":8,"power":2}],"items":[],"fires":[]}')
  me = find_me(world,id)
  $goal = {"x"=>2, "y"=>11}
  dist = manhattan_distance(me["pos"],$goal)
  puts dist
  n_turn_later = compose_n(dist,method(:update))
  w = n_turn_later.(world)
  wall?(w,$goal)
end

game_loop()

