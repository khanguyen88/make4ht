local sentenceparser = {}
local xml = require("luaxml-mod-xml")
local handler = require("luaxml-mod-handler")


local void = {area = true, base = true, br = true, col = true, hr = true, img = true, input = true, link = true, meta = true, param = true}

local actions = {
  TEXT = {text = "%s"},
  COMMENT = {start = "<!-- ", text = "%s", stop = " -->"},
  ELEMENT = {start = "<%s%s>", stop = "</%s>", void = "<%s%s />"},
  DECL = {start = "<?%s %s?>"},
  DTD = {start = "<!DOCTYPE ", text = "%s" , stop=">"}
}

local function serialize_dom(parser, current,level, output)
  local output = output or {}
  local function get_action(typ, action)
    local ac = actions[typ] or {}
    local format = ac[action] or ""
    return format
  end
  local function insert(format, ...)
    table.insert(output, string.format(format, ...))
  end
  local function prepare_attributes(attr)
    local t = {}
    local attr = attr or {}
    for k, v in pairs(attr) do
      t[#t+1] = string.format("%s='%s'", k, v)
    end
    if #t == 0 then return "" end
    -- add space before attributes
    return " " .. table.concat(t, " ")
  end
  local function start(typ, el, attr)
    local format = get_action(typ, "start")
    insert(format, el, prepare_attributes(attr))
  end
  local function text(typ, text)
    local format = get_action(typ, "text")
    insert(format, text)
  end
  local function stop(typ, el)
    local format = get_action(typ, "stop")
    insert(format,el)
  end
  local level = level or 0
  local spaces = string.rep(" ",level)
  local root= current or parser._handler.root
  local name = root._name or "unnamed"
  local xtype = root._type or "untyped"
  local text_content = root._text or ""
  local attributes = root._attr or {}
  -- if xtype == "TEXT" then
  --   print(spaces .."TEXT : " .. root._text)
  -- elseif xtype == "COMMENT" then
  --   print(spaces .. "Comment : ".. root._text)
  -- else
  --   print(spaces .. xtype .. " : " .. name)
  -- end
  -- for k, v in pairs(attributes) do
  --   print(spaces .. " ".. k.."="..v)
  -- end
  if xtype == "DTD" then
    text_content = string.format('%s %s "%s" "%s"', name, attributes["_type"],  attributes._name, attributes._uri )
    attributes = {}
  elseif xtype == "ELEMENT" and void[name] then
    local format = get_action(xtype, "void")
    insert(format, name, prepare_attributes(attributes))
    return output
  end

  start(xtype, name, attributes)
  text(xtype,text_content) 
  local children = root._children or {}
  for _, child in ipairs(children) do
    output = serialize_dom(parser,child, level + 1, output)
  end
  stop(xtype, name)
  return output
end

local parse = function(x)
  local domHandler = handler.domHandler()
  local Parser = xml.xmlParser(domHandler)
  -- preserve whitespace
  Parser.options.stripWS = nil
  Parser:parse(x)
  Parser.current = Parser._handler.root
  Parser.__index = Parser
  local parser = setmetatable({}, Parser)

  function parser.serialize(self, current)
    return table.concat(serialize_dom(self, current))
  end

  function parser.get_path(self,path, current)
    local function traverse_path(path_elements, current, t)
      local t = t or {}
      if #path_elements == 0 then 
        -- for _, x in ipairs(current._children or {}) do
          -- table.insert(t,x)
        -- end
        table.insert(t,current)
        return t
      end
      local current_path = table.remove(path_elements, 1)
      for _, x in ipairs(current._children or {}) do
        if x._type == "ELEMENT" then
          local name = string.lower(x._name)
          if name == current_path then
            t = traverse_path(path_elements, x, t)
          end
        end
      end
      return t
    end
    local current = current or self._handler.root
    local path_elements = {}
    local path = string.lower(path)
    for el in path:gmatch("([^%s]+)") do table.insert(path_elements, el) end
    return traverse_path(path_elements, current)
  end

  function parser.traverse_node_list(self, nodelist, fn)
    local nodelist = nodelist or {}
    for _, node in ipairs(nodelist) do
      for _, element in ipairs(node._children) do
        fn(element)
      end
    end
  end

  function parser.replace_node(self, old, new)
    local parent = old._parent
    local id,msg = self:find_element_pos(parent, old)
    if id then
      parent._children[id] = new
      return true
    end
    return false, msg
  end

  function parser.add_child_node(self, parent, child)
    child._parent = parent
    table.insert(parent._children, child)
  end


  function parser.copy_node(self, element)
    local t = {}
    for k, v in pairs(element) do
      if type(v) == "table" and k~="_parent" then
        t[k] = self:copy_node(v)
      else
        t[k] = v
      end
    end
    return t
  end

  function parser.create_element(self, name, attributes, parent)
    local parent = parent or self
    local new = {}
    new._type = "ELEMENT"
    new._name = name
    new._attr = attributes or {}
    new._children = {}
    new._parent = parent
    return new
  end

  function parser.remove_node(self, element)
    local parent = element._parent
    local pos = self:find_element_pos(parent, element)
    if pos then table.remove(parent._children, pos) end
  end
  
  function parser.find_element_pos(self, parent, el)
    if parent._type ~= "ELEMENT" then return nil, "The parent isn't element" end
    for i, x in ipairs(parent._children) do
      if x == el then return i end
    end
    return false, "Cannot find element"
  end
    
  -- parser:
  return parser
end


local M = {}
M.parse = parse
M.serialize= serialize_dom
return M
