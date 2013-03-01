#!/usr/bin/env lua

local parser = require("parse-silea");
local evaluator = require("evaluator");

local code = [[

let factorial function(n) {
    if equal(n 0) {
        return 1
    } else {
        return mult(n factorial(add(n -1)))
    }
}

print(factorial(20))

]];

local ast = parser.parse(code)

print("Parse Tree:\n======================================================================");

parser.print_node(ast);

print("\n\nRun:\n======================================================================");
 
evaluator.eval(ast);

print("\n\nEnvironment:\n======================================================================");
evaluator.show_env()
