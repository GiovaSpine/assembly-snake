# Assembly Snake

Just the game snake on the terminal, that i made for the Logical Circuits exam.
It was made for DOS, but i wanted to run it on a linux terminal, so i converted it by changing the interrupts of dos with linux's syscalls.

To build the image use this command when you are in the directory where the Dockerfile is located:

`docker build -t assembly-snake .`

To run the image ad a container use the following command:

`docker run -it --rm assembly-snake`