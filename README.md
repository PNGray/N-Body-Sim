# N-Body-Sim

This is an N-body simulator. It can operate in 2d or 3d mode.

## Usage

`julia gravity.jl <infile> <outfile> <dimension> <number of iterations>`

If `outfile = "stdout"`, print result to `stdout`.

Result is in a format that is readable by the anim program. Pipe or redirect results to `anim` for animation.
