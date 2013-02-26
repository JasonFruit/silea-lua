local M = {};

do   

   M.primitive = function(f)
      out = {};
      setmetatable(out,
                   {__call = function(t, ...)
                       f(unpack(arg));
                   end;});
      return out;
   end;

   M.user_defined = function(env, args, ast, eval)
      out = {};
      out.env = env;
      out.ast = ast;
      out.args = args;
      out.eval = eval;

      out.__call = function(t, ...)
         out.env.add

end;