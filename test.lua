#!/usr/bin/env lua

local parser = require("parse-silea");
local evaluator = require("evaluator");

local code = [[

fiat f

{
    let i 1

    # f encloses i
    set f function(n) {
        set i add(i 1)
        return add(n i)
    }
}

print(f(1))
print(f(1))
print(f(1))
print(f(1))
print(f(1))
print(f(1))

]];

local ast = parser.parse(code)

print("Parse Tree:\n======================================================================");

parser.print_node(ast);

print("\n\nRun:\n======================================================================");
 
evaluator.eval(ast);

print("\n\nEnvironment:\n======================================================================");
evaluator.show_env()
