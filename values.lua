local M = {};

do

   local function primitive_func(f)
      local out = {};
      setmetatable(out,
                   {__call = function(t, ...)
                       f(unpack(arg));
                   end;});
      return out;
   end;
   
   -- TODO: is there a better value for nothing?
   M["nothing"] = {};

   -- use native bools
   M["true"] = true;
   M["false"] = false;
   M["print"] = primitive_func(print);
   M["add"] = function(...)
      local out = 0;
      for _, v in ipairs(arg) do
         out = out + v;
      end;
      return out;
   end;

end;

return M;