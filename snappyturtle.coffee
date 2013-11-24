_DEBUG_ = true

MAIN_LOOP = 0

tokenizer = (s) ->
  s = s.trim()
  s = s.toUpperCase()
  r = s.match(/[A-Z0-9\-]+/g)
  return r

Point = {}

S = {}

DEFAULT_TURTLE = 
  _old_x: 49
  _old_y: 50
  _x: 50
  _y: 50
  _next_r: 0
  _step: 100
  stroke: '#000'
  fill: '#000'
  strokeWidth: 2

TURTLEICON = {}

MyTu  = _.clone(DEFAULT_TURTLE)

calc = (turtle, length = 0, rotate_degrees = null, update = true) ->
  vector = new Point( turtle._x - turtle._old_x, turtle._y - turtle._old_y)
  vector.normalize()
  if length isnt 0
    vector.length = length

  rotate_degrees = rotate_degrees or turtle._next_r
  if rotate_degrees isnt 0
    vector.angle = vector.angle + rotate_degrees

  turtle._next_r = 0 
  new_x = turtle._x + vector.x
  new_y = turtle._y + vector.y

  return [new_x, new_y]

updateTurtle = (turtle, x, y) ->
  turtle._old_y = turtle._y
  turtle._old_x = turtle._x
  turtle._x = x
  turtle._y = y
  TURTLEICON = S.group(
    S.circle(14,4,4).attr({fill:'lightgreen'})
    S.circle(20,10,3).attr({fill:'lightgreen'})
    S.circle(8,10,3).attr({fill:'lightgreen'})
    S.circle(20,18,3).attr({fill:'lightgreen'})
    S.circle(8,18,3).attr({fill:'lightgreen'})
    S.circle(14,14,8).attr({fill:'green'})
  )
  console.log(TURTLEICON)
  TURTLEICON.attr(
    x: turtle._x
    y: turtle._y
  )
  return turtle

dlog = (msg, debug = _DEBUG_ ) -> 
  if debug then console.log(msg)
  return msg
error = (msg) -> console.log('ERROR' + msg)

F =
  "SET": (args, tokens) -> set(MyTu, args); return tokens
  "GO": (args, tokens) -> go(MyTu, args); return tokens
  "JUMP": (args, tokens) -> jump(MyTu, args); return tokens
  "LEFT": (args, tokens) -> MyTu._next_r = MyTu._next_r + args[0]*-1; return tokens
  "RIGHT": (args, tokens) -> MyTu._next_r = MyTu._next_r + args[0]; return tokens
  "COLOR": (args, tokens) -> color(MyTu, args); return tokens
  "POINT": (args, tokens) -> point(MyTu, args); return tokens
  "LOOP": (args, tokens) -> loopit(args, tokens) #function returns tokens
  "STEP": (args, tokens) -> step(MyTu, args); return tokens
  "MAKE": (args, tokens) -> make(args, tokens) # function returns tokens
  "LOOPEND": (args, tokens) -> error('loopoend without start'); return tokens #do nothing as there is no loop-start
  "MAKEEND": (args, tokens) -> error('makeend without start'); return tokens
  "RESET": (args, tokens) -> reset(MyTu, args); return tokens
  "CLEAN": (args, tokens) -> clean(MyTu, args); return tokens

clean = (turtle, args) ->
  S.clear()
  return turtle

reset = (turtle, args) ->
  clean()
  turtle = MyTu = _.clone(DEFAULT_TURTLE)
  return turtle



step = (turtle, args) ->
  if args[0]
    turtle._step = args[0]
  return turtle

collectTokens = (tokens, start, end) ->
  nested = 1
  collected_tokens = []
  cloned_tokens = tokens.slice(0)
  for t in tokens
    if t is start
      nested = nested + 1
    else if t is end
      nested = nested - 1
      if nested is 0
        return collected_tokens
    collected_tokens.push(cloned_tokens.shift())
  error(start+' without a '+end)
  return tokens


make = (args, tokens) ->
  if not args[0] then return tokens
  tokens_clone = tokens.slice(0)
  collected_tokens = collectTokens(tokens, 'MAKE', 'MAKEEND')
  #dlog(tokens_clone)
  tokens_clone = tokens_clone.slice(collected_tokens.length+1)
  #dlog(tokens_clone)
  for t,i in tokens_clone
    if t is args[0]
      tokens_clone[i] = collected_tokens
  _.flatten(tokens_clone)
  


loopit = (args, tokens) ->
  if not args[0] then return tokens
  nested = 1
  collected_tokens = []
  cloned_tokens = tokens.slice(0)
  #we can't reuse collectTOkens, as we do not know if we encountered a loopend or not
  for t in tokens
    if t is "LOOP"
      nested = nested + 1
      #dlog(nested)
      #dlog(cloned_tokens)
    else if t is "LOOPEND"
      #dlog('a loopend found')
      #dlog(cloned_tokens)
      nested = nested - 1
      #dlog(nested)
      if nested is 0
        cloned_tokens.shift()
        multiple_collected_tokens = []
        for num in [0...args[0]]
          multiple_collected_tokens = multiple_collected_tokens.concat(collected_tokens) 
        return multiple_collected_tokens.concat(cloned_tokens)
        break 
    collected_tokens.push(cloned_tokens.shift())
  #dlog('no suitable loopend has been found')
  error('loop without a loopend')
  return tokens


set = (turtle, args) ->

  temp_x = args[0] ? turtle._x
  temp_y = args[1] ? turtle._y

  turtle._old_x = temp_x - (turtle._x - turtle._old_x)
  turtle._old_y = temp_y - (turtle._y - turtle._old_y)  

  turtle._x = temp_x
  turtle._y = temp_y 
  return turtle

go = (turtle, args) ->
  [new_x, new_y] = calc(turtle, args[0])
  l = S.line(turtle._x, turtle._y, new_x, new_y).attr(turtle)
  updateTurtle(turtle, new_x, new_y)

jump = (turtle, args) ->
  [new_x, new_y] = calc(turtle, args[0])
  updateTurtle(turtle, new_x, new_y)

color = (turtle, args) ->
  if args.length >= 3
    turtle.stroke = turtle.fill = 'rgb('+args[0]+','+args[1]+','+args[2]+')'
  if args.length is 1
    turtle.stroke = turtle.fill = args[0]
  return turtle

point = (turtle, args) ->
  d = args[0] ? 5
  S.circle(turtle._x, turtle._y, d).attr(turtle)



type_it = (x) ->
  if (xi = parseInt(x))+'' is x
    return xi
  else
    return x

preparser = () -> console.log('preparser')

execute_loop = (tokens) ->
  t = tokens.shift()
  #dlog(t)
  args = []
  if (e = F[t])
    #dlog(e)
    tokens_clone = tokens.slice(0)
    for x in tokens_clone
      if not F[x]
        args.push(type_it(tokens.shift()))
      else
        break
    tokens = e(args, tokens)

  if tokens.length > 0
    MAIN_LOOP =  Meteor.setTimeout((->execute_loop(tokens)), MyTu._step)



#test = "GO 50 LEFT 45 JUMP 30 GO 40 -20 30 50 RIGHT 50 GO 100 COLOR RED POINT"
#test = "SET 80 80 JUMP 100 GO 90 RIGHT 90 SET 200 200 COLOR 255 77 0 LOOP 2 GO 50 RIGHT 25 LOOP 2 GO 10 RIGHT 15 LOOPEND LOOPEND JUMP 50 GO 50 POINT 40 LEFT 90 GO 50 LEFT 90 GO 50"
#test = "set 200 200 loop 10 go 40 left 45 loop step 500 2 go 10 left 90 loopend step 100 loopend"
#test = "set 200 200 step 100 loop 2 go 10 loop color black go 20 color red go 20 loopend left 45 loopend"
#test = "set 200 200 loop 4 go 25 loop 2 color red go 25 loopend color black left 90 loopend"
test = "step 50 set 200 200 make line go 100 makeend make square loop 4 line right 90 loopend makeend 
loop 100 square left 11 loopend"

if Meteor.isClient
  Point = window.paper.Point
  editor = {}

  getAndExecute = () ->
    Meteor.clearTimeout(MAIN_LOOP)
    #RESET THE TURTLE
    #S.clear()
    Session.set('code', editor.getValue())
    tokens = tokenizer(Session.get('code'))
    execute_loop(tokens)

  keypress.combo('meta r', (e) ->
    e.preventDefault()
    getAndExecute()
  )

  svg_render_count = 0 
  #there was a bug with created
  Template.svgworld.rendered = () ->
      if svg_render_count is 0
        S = Snap('#svg')

        #smallCircle = S.circle(100, 150, 70)
      svg_render_count = svg_render_count + 1

  editor_render_count = 0
  Template.editor.rendered = () ->
    if editor_render_count is 0
      #editor = @find('#editor')
      editor = ace.edit("editor")
      getAndExecute()
    editor_render_count = editor_render_count + 1
    #tokens = tokenizer(editor.innerHTML)
    #execute_loop(tokens)






