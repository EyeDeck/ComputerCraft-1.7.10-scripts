--[[
A crude API for drawing buttons to CC screen, and
mapping raw (x,y) input coords to drawn buttons.
--]]

button_registry = {}

--[[
m = monitor to write to
x,y = top left coord of button
w,h = width and height of button
txtcolor = text color of button, e.g. colors.white
bgcolor = background color of button e.g. colors.lime
text = text to draw on button
name = name of button to add to button registry
--]]
function drawButton(m,x,y,w,h,txtcolor,bgcolor,text,name)
  local old_term = term.redirect(m)
  local old_bg = term.getBackgroundColor()
  local old_tx = term.getTextColor()
  local old_posx, old_posy = term.getCursorPos()
  
  paintutils.drawLine(x+1,   y,     x+w-2, y,     colors.lightGray)
  paintutils.drawLine(x+1,   y+h-1, x+w-2, y+h-1, colors.gray)
  paintutils.drawLine(x, 	   y+1,   x,     y+h-2, colors.gray)
  paintutils.drawLine(x+w-1, y+1,   x+w-1, y+h-2, colors.lightGray)
  paintutils.drawFilledBox(x+1, y+1, x+w-2, y+h-2, bgcolor)
  
  term.setTextColor(txtcolor)
  term.setBackgroundColor(bgcolor)
  if type(text) == "table" then
    local line_ct = #text
    local y_offset = -math.floor(line_ct/2)
    for k,v in pairs(text) do
      term.setCursorPos(x+math.floor((w-#v)/2),y+y_offset+k+math.floor((h-1)/2))
      term.write(v)
    end
  else
    term.setCursorPos(x+math.floor((w-#text)/2),y+math.floor((h-1)/2))
    term.write(text)
  end
  
  term.setCursorPos(old_posx, old_posy)
  term.setTextColor(old_tx)
  term.setBackgroundColor(old_bg)
  term.redirect(old_term)
  
  if name ~= nil then
    button_registry[name] = {
      m=m,
      x=x+1, y=y+1,
      x2=x+w-2, y2=y+h-2,
      x_raw = x, y_raw = y,
      w_raw = w, h_raw = h,
      tc=txtcolor,
      bc=bgcolor,
      text=text,
      name=name
    }
  end
end

--Redraws a named button, ignoring nil values.
function redrawButton(m,x,y,w,h,txtcolor,bgcolor,text,name)
  drawButton(
    m and m or button_registry[name].m,
    x and x or button_registry[name].x_raw,
    y and y or button_registry[name].y_raw,
    w and w or button_registry[name].w_raw,
    h and h or button_registry[name].h_raw,
    txtcolor and txtcolor or button_registry[name].tc,
    bgcolor and bgcolor or button_registry[name].bc,
    text and text or button_registry[name].text,
    name
  )
end

function getButton(x,y)
  for _,v in pairs(button_registry) do
    if x >= v.x and x <= v.x2 and y >= v.y and y <= v.y2 then
      return v.name
    end
  end
  return false
end

function removeButton(name)
  if button_registry[name] ~= nil then
    button_registry[name] = nil
    return true
  end
  return false
end