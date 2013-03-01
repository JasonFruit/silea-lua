local M = {};

do

   local functions = require("functions");
   
   local nothing = {};
   setmetatable(nothing,
                {__tostring = function() return "nothing"; end;});
   M["nothing"] = nothing;

   -- use native bools
   M["true"] = true;
   M["false"] = false;
   M["print"] = functions.primitive(print);
   M["add"] = functions.primitive(function(...)
                                     local out = 0;
                                     for _, v in ipairs(arg) do
                                        out = out + v;
                                     end;
                                     return out;
                                  end);

end;

return M;