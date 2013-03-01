local M = {};

do   

   M.primitive = function(f)
      local out = {};
      setmetatable(out,
                   {__call = function(t, ...)
                       return f(unpack(arg));
                   end,
                    __tostring = function()
                       return "(primitive function)";
                    end});
      return out;
   end;

   M.user_defined = function(env, args, ast, eval, source)
      local out = {};
      out.env = env;
      out.ast = ast;
      out.args = args;
      out.eval = eval;

      setmetatable(out,
                   {__call = function(t, ...)

                       local env = out.env.temp_new();
                       
                       for i, v in ipairs(out.args) do
                          env.define(v, arg[i]);
                       end;
                       
                       -- yes, we use exceptions to handle return values
                       local success, retval = pcall(eval, out.ast, env);
                       
                       if success then
                          return nil;
                       else
                          return retval;
                       end;
                       
                   end,
                    __tostring = function(t)
                       return "user-defined " .. source;
                    end});
      
      return out;

   end;

end;

return M;