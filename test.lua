#!/usr/bin/env lua

local parser = require("parse-silea");
local evaluator = require("evaluator");

local code = [[

let struct function(a b c) {
    return <a: a b: b c: c>
}
print(struct(3 5 "dog"))
]];

local ast = parser.parse(code)

print("Parse Tree:\n======================================================================");

parser.print_node(ast);

print("\n\nRun:\n======================================================================");
 
evaluator.eval(ast);

print("\n\nEnvironment:\n======================================================================");
evaluator.show_env()
