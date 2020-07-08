// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed. 
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// Put your code here.

(MAIN_LOOP)
@SCREEN            // store top of screen into @screen_location
D=A
@screen_location
M=D

@KBD               // read key into D
D=M

// If no key is pressed, the value read is the color
(DETERMINE_COLOR)
@STORE_COLOR
D; JEQ

// Otherwise, convert the value to -1
D=-1

(STORE_COLOR)
@color             // 9.
M=D

(FILL_SCREEN)
@screen_location   // 11. if i == KBD; goto MAIN_LOOP
D=M
@KBD               // 13.
D=D-A
@MAIN_LOOP
D; JEQ

@color             // 17. load the color
D=M
@screen_location   // 19. load the screen pointer
A=M
M=D                // store the color

D=A+1              // 22. increase the screen pointer
@screen_location
M=D

@FILL_SCREEN // restart the loop
0; JMP
