module Grid_lib

using Vec_lib
using Body_lib
using Linked_list

export Grid

struct Grid{T <: Vec}
    origin::T
    op_corner::T
    elements::Link{T}
    Grid(origin, size) = new{typeof(origin)}(origin, origin + T(size), Link{typeof(origin)}())
end

function contains(grid::Grid{T}, vec::T) where T
    quad1(vec - grid.origin) && quad3_7(vec - grid.op_corner)
end


end
