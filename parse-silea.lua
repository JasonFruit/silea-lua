local M = {}

do

   local io = require "io";

   -- bring stuff from lpeg local
   local lpeg = require "lpeg";
   local P, R, S, C, V, Cc, Ct, Cmt, Cg, Cb = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.V, lpeg.Cc, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb;
   local locale = lpeg.locale

   -- delete a numerically-indexed value from a table, adjusting
   -- succeeding values to leave no empty spaces.  Leaves
   -- non-numeric keys alone.  Does not work for tables with
   -- negative or fractional keys.
   local function delete(t, i)

      -- delete the element
      t[i] = nil;

      -- return the max numeric key in tbl
      local function max_ind(tbl)
         local out = -1;
         for k, v in pairs(tbl) do
            if type(k) == "number" and k > out then
               out = k;
            end
         end

         return out;
      end

      local max_id = max_ind(t);

      -- if there are numerically-keyed values above the deleted
      -- item, shift them down
      if max_id > i then
         for n = i + 1, max_id do
            t[n-1] = t[n];
         end

         t[max_id] = nil;
      end;

   end

   -- AST functions ----------------------------------------------------

   -- special AST functions for atoms and idents
   local function makeIdent(text)
      return {name = "ident",
              value = text};
   end

   local function makeInt(text)
      return {name = "int",
              value = text};
   end

   local function makeReal(text)
      return {name = "real",
              value = text};
   end

   local function makeBool(text)
      return {name = "bool",
              value = text};
   end

   local function makeString(text)
      return {name = "string",
              value = text};
   end

   -- make an AST node using the first capture as the node name
   local function makeNamed(...)

      local out = {name = arg[1]};

      for i = 2, arg.n do
         out[i-1] = arg[i];
      end

      return out

   end

   -- return a function that will add the specified name property
   -- to the capture table
   local function namerFunc(name)

      return function(...)

         local out = {};

         out['name'] = name;

         for i = 1, arg.n do
            out[i] = arg[i];
         end;

         return out;
             end;

   end;

   -- begin actual parser --------------------------------------------

   -- characters that can start identifiers
   local ident_init_char = R("AZ", "az") + S("~!@#$%^&*=+|';,?-_");

   -- characters that can follow the first char in an identifier
   local ident_char = ident_init_char + R("09");

   -- make a keyword
   local function K (k) -- keyword
      return P(k) * -(ident_char);
   end

   -- all Silea keywords
   local keywords = K("let") + K("set") + K("if") + K("branch") +
      K("when") + K("for") + K("in") + K("load") +
      K("dump") + K("true") + K("false") + K("fiat") +
      K("while") + K("else") + K("function") + K("nothing") + K("or") +
      K("try") + K("throw") + K("catch");

   local linenum = 1;

   local function incrLineNum(...)
      linenum = linenum + 1;
      return {name="linenum",
              linenum};
   end

   -- an ident starts with an init char, has as many body chars as you
   -- want, and is not a keyword
   local ident = (ident_init_char * ident_char^0 - (keywords + P(" "))) / makeIdent;
   -- match a literal newline
   local newline = C(P("\n")) / incrLineNum;

   -- a comment starts with a hash and continues to the end of the
   -- line or file no matter what is in between
   local comment = P("#") * (P(1) - newline)^0 * (newline + (-P(1)));

   -- matches zero or more white spaces
   local ws = (S(" \r\t") + newline + comment)^0;

   -- fiat statements are 'fiat' plus an identifier
   local fiat = (C("fiat") * ws * ident) / makeNamed;

   -- integers are an optional sign (+/-) followed by one or more
   -- digits
   local sign = S("+-");
   local digit = R("09");
   local integer = C(sign^-1 * digit^1) / makeInt;

   -- valid reals are a point preceded and/or followed by one or more
   -- digits and preceded by an optional sign
   local point = P(".")
   local real = C(sign^-1 * (digit^1 * point * (digit^1)^-1 + point * digit^1)) / makeReal;

   -- a string is surrounded by double-quotes, and may include the
   -- following escapes: \\, \r, \n, \"
   local string = P('"') * C(((1 - S('"\r\n\\')) + (P('\\') * 1)) ^ 0) * '"' / makeString;

   local param = ident + (P(":rest") / makeIdent)
   --- function params are any number of identifiers enclosed in
   --- parentheses, possibly ending with :rest
   local params = P("(") * ws * (param * ws)^0 * ws * P(")") / namerFunc("params");

   local sg = P({"program"; -- name of the entry point
         -- a program is any number of statements
         -- with whitespace on either side
         program = C((ws * V("statement"))^0) * ws * -P(1) / namerFunc("program"),
         expression = string +
            real +
            integer +
            C(K("true")) / makeBool +
            C(K("false")) / makeBool +
            V("func") +
            V("accessed_expr") +
            V("call") +
            V("or_ex") +
            ident +
            C(K("nothing")) / makeIdent +
            V("array") +
            V("container"),
         -- args are any number of exprs surrounded by ()
         args = (P("(") * (ws * V("expression"))^0 * ws * P(")")) / namerFunc('args'),
         func_for_call = ident + V("func"),
         array_yielders = V("call") + V("array") + ident,
         container_yielders = V("call") + V("container") + ident,
         for_st = (C(K("for")) * ws * ident * ws * K("in") * ws * V("expression") * ws * V("scope")) / makeNamed,
         while_st = (C(K("while")) * ws * V("expression") * ws * V("scope")) / makeNamed,
         try_st = (C(K("try")) * ws * V("scope") * ws * K("catch") * ws * V("expression") * ws * V("scope")) / makeNamed,
         throw = (C(K("throw")) * ws * V("expression")) / makeNamed,
         dump = (C(K("dump")) * ws * V("container_yielders")) / makeNamed,
         load = (C(K("load")) * ws * V("expression")) / makeNamed,
         array_access = (P("[") * V("expression") * P("]")) / namerFunc("array_access"),
         accessed_expr = ((V("array_yielders") + V("container_yielders")) *
                          ((P(".") * V("call")) +
                           (P(".") * ident) +
                           V("array_access"))^1) / namerFunc("access"),
         call = (V("func_for_call") * ws * V("args")) / namerFunc("call"),
         or_ex = (C(K("or")) * ws * V("args")) / makeNamed,
         set = C(K("set")) * ws * (V("accessed_expr") + ident) * ws * V("expression") / makeNamed,
         let = (C(K("let")) * ws * ident * ws * V("expression")) / makeNamed,
         if_st = (C(K("if")) * ws * V("expression") * ws * V("scope") * (ws * K("else") * ws * V("scope"))^-1) / makeNamed,
         case = (K("when") * ws * V("expression") * ws * V("scope")) / namerFunc("case"),
         branch = (K("branch") * (ws * V("case"))^0) / namerFunc("branch"),
         array = (P("[") * ws * V("expression")^-1 * (ws * V("expression"))^0 * ws * P("]")) / namerFunc("array"),
         attrib = (ident * ws * P(":") * ws * V("expression")) / namerFunc("attrib"),
         container = (P("<") * (ws * V("attrib"))^0 * ws * P(">")) / namerFunc("container"),
         func = C(P("function")) * ws * params * ws *  V("scope") / makeNamed,
         return_st = (C(P("return")) * ws * V("expression")) / makeNamed,
         statement = C(V("accessed_expr") +
                       V("call") +
                       V("let") +
                       fiat +
                       V("set") +
                       V("scope") +
                       V("if_st") +
                       V("for_st") +
                       V("while_st") +
                       V("try_st") +
                       V("throw") +
                       V("branch") +
                       V("return_st") +
                       V("dump") +
                       V("load")) / namerFunc("statement"),
         scope = P("{") * C((ws * V("statement"))^0) * ws * P("}") / namerFunc("scope")
                })

   local handle_linenum = 1;

   -- removes linenum nodes and adds linenum properties to
   -- remaining nodes
   local function handle_linenums(node)

      local i = 1;
      while node[i] do
         if node[i].name == "linenum" then
            handle_linenum = node[i][1];
            delete(node, i);
         else
            if type(node[i]) == "table" then
               node[i].linenum = handle_linenum;
               handle_linenums(node[i]);
            end;
            i = i + 1;
         end;
      end;
   end;

   -- do the parse, capturing matches and then revising the
   -- tree to be more easily-compiled or -interpreted
   local function parse(code)

      local ast = sg:match(code);

      if ast then
         handle_linenums(ast);
      end;

      return ast;

   end

   -- pretty-print an AST node and its children (internal
   -- recursive version)
   local function print_node_r(node, indent)
      if type(node) == "table" then
         print(indent .. node["name"] .. ": ")
         for k, v in pairs(node) do
            if k ~= "name" then
               print(indent .. k .. " " .. tostring(v));
               print_node_r(v, indent .. "    |")
            end
         end
      end
   end

   -- pretty-print an AST node and its children (low-stress
   -- public version)
   local function print_node(node)
      print_node_r(node, "")
   end

   M.parse = parse;
   M.print_node = print_node;

end

return M;
