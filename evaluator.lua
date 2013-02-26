-- Implements evaluation of Silea programs

-- the evaluator
local M = {};

do

   local eval;
   
   -- the environment manager for the evaluator
   local environ = require("environ");

   local function ident_name(ast)
      return ast.value;
   end;
   
   -- evaluate the AST of a fiat statement
   local function eval_fiat(ast)

      -- TODO: remove for speed?
      assert(ast["name"] == "fiat",
             "Not a fiat node.");

      environ.current().define(ident_name(ast[1]));

   end;

   -- evaluate the AST of a let statement
   local function eval_let(ast)

      -- TODO: remove for speed?
      assert(ast["name"] == "let",
             "Not a let node.");

      environ.current().define(ident_name(ast[1]),
                               eval(ast[2]));

   end;

   local function eval_scope(ast)

      environ.current().add_new();

      for i, v in ipairs(ast) do
         if i > 1 then
            eval(v);
         end;
      end;

      environ.current().close();
      
   end;

   -- evaluate the AST of a set statement
   local function eval_set(ast)

      -- TODO: remove for speed?
      assert(ast["name"] == "set",
             "Not a set node.");

      environ.current().set(ident_name(ast[1]),
                            eval(ast[2]));

   end;

   -- evaluate the AST of an integer expression
   local function eval_int(ast)

      -- TODO: remove for speed?
      assert(ast["name"] == "int",
             "Not an int node.");

      return tonumber(ast["value"]);

   end;

   -- evaluate the AST of a real numeric expression
   local function eval_real(ast)

      -- TODO: remove for speed?
      assert(ast["name"] == "real",
             "Not a real node.");

      return tonumber(ast["value"]);

   end;

   -- evaluate the AST of a string expression
   local function eval_string(ast)

      -- TODO: remove for speed?
      assert(ast["name"] == "string",
             "Not a string node.");

      -- TODO: figure out how to make this safe
      return (loadstring("return \"" .. ast.value .. "\""))();
      
   end;

   -- evaluate the AST for a statement
   local function eval_statement(ast)

      -- TODO: remove for speed?
      assert(ast["name"] == "statement",
             "Not a statement.");

      -- evaluate the statement's content but do not return anything
      eval(ast[2]);

   end;

   local function eval_call(ast)

      local f = eval(ast[1]);
      local args = {};

      for i, arg_ast in ipairs(ast[2]) do
         args[i] = eval(arg_ast);
      end;

      return f(unpack(args));
      
   end;

   -- evaluate the AST for an identifier
   local function eval_ident(ast)
      
      -- TODO: remove for speed?
      assert(ast["name"] == "ident",
             "Not an ident.");

      -- return the value associated with the name
      return environ.current().find(ast.value);

   end;

   -- evaluate any sub-program AST node
   eval = function(ast)

      local name = ast["name"];
      
      if name == "scope" then
         return eval_scope(ast);
      elseif name == "statement" then
         return eval_statement(ast);
      elseif name == "call" then
         return eval_call(ast);
      elseif name == "ident" then
         return eval_ident(ast);
      elseif name == "fiat" then
         return eval_fiat(ast);
      elseif name == "let" then
         return eval_let(ast);
      elseif name == "set" then
         return eval_set(ast);
      elseif name == "int" then
         return eval_int(ast);
      elseif name == "real" then
         return eval_real(ast);
      elseif name == "string" then
         return eval_string(ast);
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
            eval(statement);
         end;
      end;
      
   end;

   M.show_env = function()
      environ.pretty_print();
   end;
   
end;

return M;