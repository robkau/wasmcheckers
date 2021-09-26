##Overview
This repository implements partial logic for the game [Checkers](https://en.wikipedia.org/wiki/Draughts) in [WebAssembly Text Format](https://developer.mozilla.org/en-US/docs/WebAssembly/Understanding_the_text_format) 

This follows the material from Chapter 1 of [Programming WebAssembly in Rust by Kevin Hoffman](https://pragprog.com/titles/khrust/programming-webassembly-with-rust/)

Notes:
- There is no interactive game implemented, only core checkers logic functions written in the .wat file.  
- The .wat file is compiled to a WASM module which exports several functions that could be used to build and visualize a checkers game (in the browser).  
- There are unit tests in file test.html to verify the built .wasm file is running correctly.

## Requirements:
wat2wasm binary is required for compiling .wat file into .wasm module.  
Get it by installing the [WebAssembly Binary Toolkit](https://github.com/WebAssembly/wabt)

##To Build:
Compile .wat file to .wasm module:  
*wat2wasm checkers.wat -o checkers.wasm*

##To Test:
1) Start HTTP server to serve test.html and checkers.wasm:  
  *python3 -m http.server*
2) Browse to file *test.html* and latest checkers.wasm file will be loaded and tested. Green is pass and red is fail.  
  *http://localhost:8000/index.html*