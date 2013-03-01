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
   M["mult"] = functions.primitive(function(...)
                                     local out = 1;
                                     for _, v in ipairs(arg) do
                                        out = out * v;
                                     end;
                                     return out;
                                  end);
   M["equal"] = functions.primitive(function(...)
                                       if #arg == 0 then
                                          
                                          return true;
                                          
                                       else

                                          local v1 = arg[1];
                                          
                                          for _, v in ipairs(arg) do
                                             if v ~= v1 then
                                                return false;
                                             end;
                                          end;
                                          
                                          return true;
                                          
                                       end;
                                    end);

end;

return M;