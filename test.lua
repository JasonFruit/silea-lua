local parser = require("parse-silea");
local evaluator = require("evaluator");

local code = [[fiat lux
               {
                  let some-num 3.33
                  let another 4
                  {
                     set lux "a string"
                     print(add(some-num another))
                  }
               }
               print(lux)]];

local ast = parser.parse(code)

print("Parse Tree:\n======================================================================");

parser.print_node(ast);

print("\n\nRun:\n======================================================================");
 
evaluator.eval(ast);

print("\n\nEnvironment:\n======================================================================");
evaluator.show_env()