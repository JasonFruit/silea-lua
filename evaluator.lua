-- Implements evaluation of Silea programs

-- the evaluator
local M = {};

do

   local eval;
   
   -- the environment manager for the evaluator
   local environ = require("environ");

   -- the definitions for primitive and user-defined functions
   local functions = require("functions");

   local function ident_name(ast)
      return ast.value;
   end;
   
   -- evaluate the AST of a fiat statement
   local function eval_fiat(ast, env)

      -- TODO: remove for speed?
      assert(ast["name"] == "fiat",
             "Not a fiat node.");

      env.define(ident_name(ast[1]));

   end;

   -- evaluate the AST of a let statement
   local function eval_let(ast, env)

      -- TODO: remove for speed?
      assert(ast["name"] == "let",
             "Not a let node.");

      env.define(ident_name(ast[1]),
                 eval(ast[2], env));

   end;

   local function eval_scope(ast, env)

      env = env.temp_new();

      for i, v in ipairs(ast) do
         if i > 1 then
            eval(v, env);
         end;
      end;      

   end;

   -- evaluate the AST of a set statement
   local function eval_set(ast, env)

      -- TODO: remove for speed?
      assert(ast["name"] == "set",
             "Not a set node.");

      env.set(ident_name(ast[1]),
              eval(ast[2], env));

   end;

   -- evaluate the AST of an integer expression
   local function eval_int(ast, env)

      -- TODO: remove for speed?
      assert(ast["name"] == "int",
             "Not an int node.");

      return tonumber(ast["value"]);

   end;

   -- evaluate the AST of a real numeric expression
   local function eval_real(ast, env)

      -- TODO: remove for speed?
      assert(ast["name"] == "real",
             "Not a real node.");

      return tonumber(ast["value"]);

   end;

   -- evaluate the AST of a string expression
   local function eval_string(ast, env)

      -- TODO: remove for speed?
      assert(ast["name"] == "string",
             "Not a string node.");

      -- TODO: figure out how to make this safe
      return (loadstring("return \"" .. ast.value .. "\""))();
      
   end;

   local function eval_bool(ast, env)
      if ast.value == "true" then
         return true;
      else
         return false;
      end;
   end;

   -- evaluate the AST of a function expression
   local function eval_function(ast, env)
      local args = {};
      
      for i, v in ipairs(ast[2]) do
         args[i] = v.value;
      end;

      return functions.user_defined(env,
                                    args,
                                    ast[3],
                                    eval,
                                    ast[1]);
   end;

   -- evaluate the AST for a statement
   local function eval_statement(ast, env)

      -- TODO: remove for speed?
      assert(ast["name"] == "statement",
             "Not a statement.");

      -- evaluate the statement's content but do not return anything
      eval(ast[2], env);

   end;

   local function eval_call(ast, env)

      local f = eval(ast[1], env);
      local args = {};

      for i, arg_ast in ipairs(ast[2]) do
         args[i] = eval(arg_ast, env);
      end;

      return f(unpack(args));
      
   end;

   -- evaluate the AST for an identifier
   local function eval_ident(ast, env)
      
      -- TODO: remove for speed?
      assert(ast["name"] == "ident",
             "Not an ident.");

      -- return the value associated with the name
      return env.find(ast.value);

   end;

   local function eval_return(ast, env)

      error(eval(ast[1], env), 0);
      
   end;

   local function eval_array(ast, env)

      local out = {};

      setmetatable(out, {__tostring = function()
                            return "[" .. table.concat(out, " ") .. "]";
      end});

      for i, v in ipairs(ast) do
         out[i] = eval(v, env);
      end;

      return out;

   end;

   local function eval_attrib(ast, env)
      return ident_name(ast[1]), eval(ast[2], env);
   end;
   
   local function eval_container(ast, env)
      local out = {};

      setmetatable(out,
                   {__tostring = function(t)
                       local s = "<";
                       for k, v in pairs(t) do
                          s = s .. " " .. tostring(k) .. ": " .. tostring(v);
                       end;
                       return s .. " >";
                   end;});                       
      
      for i, v in ipairs(ast) do
         local key, val = eval_attrib(v, env);
         out[key] = val;
      end;

      return out;
      
   end;

   local function eval_for(ast, env)
      env = env.temp_new();

      local var = ident_name(ast[1]);
      local arr = eval(ast[2], env);

      env.define(var);
      
      for i, v in ipairs(arr) do
         env.set(var, v);
         eval_scope(ast[3], env);
      end;
      
   end;

   local function eval_if(ast, env)
      local cond = eval(ast[1], env);

      -- the only false values in Silea are false and nothing
      if (cond ~= false) and (cond ~= env.find("nothing")) then
         eval(ast[2], env);
      else
         if #ast > 2 then
            eval(ast[3], env);
         end;
      end;
   end;

   -- evaluate any sub-program AST node
   eval = function(ast, env)

      local name = ast["name"];
      
      if name == "scope" then
         return eval_scope(ast, env);
      elseif name == "statement" then
         return eval_statement(ast, env);
      elseif name == "call" then
         return eval_call(ast, env);
      elseif name == "ident" then
         return eval_ident(ast, env);
      elseif name == "fiat" then
         return eval_fiat(ast, env);
      elseif name == "let" then
         return eval_let(ast, env);
      elseif name == "set" then
         return eval_set(ast, env);
      elseif name == "int" then
         return eval_int(ast, env);
      elseif name == "real" then
         return eval_real(ast, env);
      elseif name == "string" then
         return eval_string(ast, env);
      elseif name == "bool" then
         return eval_bool(ast, env);
      elseif name == "function" then
         return eval_function(ast, env);
      elseif name == "array" then
         return eval_array(ast, env);
      elseif name == "container" then
         return eval_container(ast, env);
      elseif name == "return" then
         return eval_return(ast, env);
      elseif name == "for" then
         return eval_for(ast, env);
      elseif name == "if" then
         return eval_if(ast, env);
      else
         error("Node type '" .. name .. "' not yet implemented.");
      end;

   end;

   -- evaluate a program node's AST
   M.eval = function(ast)

      assert(ast["name"] == "program",
             "Not a program node.");

      for k, statement in pairs(ast) do
         -- ignore the name and the first numbered node, which
         -- contains the text of the program
         if (k ~= "name") and (k ~= 1) then
            eval(statement, environ.current());
         end;
      end;
      
   end;

   M.show_env = function()
      environ.pretty_print();
   end;
   
end;

return M;