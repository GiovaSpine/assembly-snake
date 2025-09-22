# Assembly Snake

Just a game of snake on the terminal, that I made while exercising for the Logical Circuits exam for fun.
It was made for DOS, but I wanted to run it on a linux terminal to make it more accessible, and so I converted it by changing the interrupts of DOS with linux's syscalls or libc and ncurses functions.

To build the image use this command when you are in the directory where the Dockerfile is located:<br>
`docker build -t assembly-snake .`

To run the image as a container use the following command:<br>
`docker run -it --rm assembly-snake`

## To do

As of right now, if when generating a random position for the fruit (the food that the snake eats), we hit the snake body, we have a not valid position.
Instead of finding a new random position we look in order all the map for a free spot (a spot without the snake body), but as a result of this, it's common to have the fruit in the first cell (top-left corner) when the snake occupy a lot of the map, because there is a high chance to hit the body.<br>
We might do something different like searching a new spot around the cell that hitted the body.