local M = {};

do

   -- bring in the global values
   local values = require("values");
   local current;
   
   -- make a new empty environment with an optional parent
   local function make_empty(parent)
      local env = {};
      local meta = {};

      -- set the env's __index metamethod to contain functions that
      -- will not be returned by the pairs/ipairs generators
      meta.__index = {["parent"] = function()
                         return parent;
                                   end,
                      ["add_new"] = function()
                         current = make_empty(env);
                      end,
                      ["temp_new"] = function()
                         -- a temporary new child environment, useful
                         -- for storing function arguments
                         return make_empty(env);
                      end,
                      ["close"] = function()
                         -- an environment without a parent is
                         -- top-level and not susceptible to closing
                         assert(parent,
                                "Cannot close top-level environment.");
                         current = parent;
                      end,
                      -- find a name in the current environment or any
                      -- higher one; if not found, error out.
                      ["find"] = function(name)
                         if env[name] then
                            return env[name], env;
                         elseif parent then
                            return parent.find(name);
                         else
                            error("Name '" .. name .. "' is undefined.");
                         end;
                      end,
                      ["define"] = function(name, value)
                         assert(not current["name"],
                                "Name '" .. name .. "' is already defined in the current scope.");
                         
                         value = value or values.nothing;
                         current[name] = value;
                      end,
                      ["set"] = function(name, value)
                         local val, e = env.find(name);
                         e[name] = value;
                      end};
      
      setmetatable(env, meta);
      
      return env;

   end;

   -- returns a filled-out global environment
   local function make_global() 

      -- start with an empty environment
      local env = make_empty();

      -- add the global values to the global environment
      for k, v in pairs(values) do
         env[k] = v;
      end;

      return env;
      
   end;

   -- the starting environments
   current = make_global();

   -- return the current environment (so it can't be overwritten by
   -- users)
   function M.current()
      return current;
   end;

   -- print an environment's contents
   local function print_env(env)
      for k, v in pairs(env) do
         print(k, v);
      end;
   end;

   -- pretty-print the whole set of environments.
   -- TODO: make it prettier-print
   M.pretty_print = function()

      local env = current;

      print_env(env);
      
      while env.parent() do
         print(string.rep("-", 70));
         env = env.parent();
         print_env(env);
      end;

   end;
   
end;

return M;