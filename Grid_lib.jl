module Grid_lib

using Vec_lib
using Body_lib
using Linked_list

export Grid, check_grid, update_grid, make_box, init_grid, cycle_leapfrog_grid

struct Grid{T <: Vec}
    origin::T
    op_corner::T
    elements::Link{Body{T}}
    buffer::Vector{Link{Body{T}}}
    Grid(origin, size) = begin
        T = typeof(origin)
        x = new{T}(origin, origin + T(size), Link{Body{T}}(), Vector{Link{Body{T}}}())
        for i in 1:Threads.nthreads()
            push!(x.buffer, Link{Body{T}}())
        end
        return x
    end
end

function check_grid(box::Array{Grid{Vec2d}, 2})
    (sx, sy) = strides(box)
    Threads.@threads for n in eachindex(box)
        threadid = Threads.threadid()
        new = n
        grid = box[n]
        current = grid.elements.next
        while !(current === grid.elements)
            next = current.next
            (x1, y1) = quad_relative(current.val.pos, grid.origin)
            (x2, y2) = quad_relative(current.val.pos, grid.op_corner)
            x_offset = div(x1 + x2, 2)
            y_offset = div(y1 + y2, 2)
            if x_offset != 0 || x_offset != 0
                remove_link(current)
                new += x_offset * sx + y_offset * sy
                new_grid = box[new]
                current.val.tag = new
                push_link(new_grid.buffer[threadid], current)
            end
            current = next
        end
    end
end

function check_grid(box::Array{Grid{Vec3d}, 3})
    (sx, sy, sz) = strides(box)
    Threads.@threads for n in eachindex(box)
        threadid = Threads.threadid()
        new = n
        grid = box[n]
        current = grid.elements.next
        while !(current === grid.elements)
            next = current.next
            (x1, y1, z1) = quad_relative(current.val.pos, grid.origin)
            (x2, y2, z2) = quad_relative(current.val.pos, grid.op_corner)
            x_offset = div(x1 + x2, 2)
            y_offset = div(y1 + y2, 2)
            z_offset = div(z1 + z2, 2)
            if x_offset != 0 || x_offset != 0 || z_offset != 0
                remove_link(current)
                new += x_offset * sx + y_offset * sy + z_offset * sz
                new_grid = box[new]
                current.val.tag = new
                push_link(new_grid.buffer[threadid], current)
            end
            current = next
        end
    end
end

function update_grid(box::Array{Grid{T}}) where {T}
    Threads.@threads for n in box
        for i in n.buffer
            concat(n.elements, i)
        end
    end
end

function make_box(origin::Vec2d, size::Float64, n::Int64)::Array{Grid{Vec2d}, 2}
    pad = size / n
    padx = Vec2d(pad, 0)
    pady = Vec2d(0, pad)
    box = Array{Grid{Vec2d}}(undef, n, n)
    for j in 1:n
        oriy = origin + ((j - 1.0) * pady)
        for i in 1:n
            orix = oriy + ((i - 1.0) * padx)
            box[i, j] = Grid(orix, pad)
        end
    end
    box
end

function make_box(origin::Vec3d, size::Float64, n::Int64)::Array{Grid{Vec3d}, 3}
    pad = size / n
    padx = Vec3d(pad, 0, 0)
    pady = Vec3d(0, pad, 0)
    padz = Vec3d(0, 0, pad)
    box = Array{Grid{Vec3d}}(undef, n, n, n)
    for k in 1:n
        oriz = origin + ((k - 1.0) * padz)
        for j in 1:n
            oriy = oriz + ((j -1.0) * pady)
            for i in 1:n
                orix = oriy + ((i - 1.0) * padx)
                box[i, j, k] = Grid(orix, pad)
            end
        end
    end
    box
end

function push_grid(box::Array{Grid{Vec2d}, 2}, b::Body{Vec2d})
    for n in eachindex(box)
        i = box[n]
        (x1, y1) = quad_relative(b.pos, i.origin)
        (x2, y2) = quad_relative(b.pos, i.op_corner)
        x_offset = x1 + x2
        y_offset = y1 + y2
        if x_offset == 0 && y_offset == 0
            b.tag = n
            push_link(i.buffer[Threads.threadid()], Link{Body{Vec2d}}(b))
            break
        end
    end
end

function push_grid(box::Array{Grid{Vec3d}, 3}, b::Body{Vec3d})
    for n in eachindex(box)
        i = box[n]
        (x1, y1, z1) = quad_relative(b.pos, i.origin)
        (x2, y2, z2) = quad_relative(b.pos, i.op_corner)
        x_offset = x1 + x2
        y_offset = y1 + y2
        z_offset = z1 + z2
        if x_offset == 0 && y_offset == 0 && z_offset == 0
            b.tag = n
            push_link(i.buffer[Threads.threadid()], Link{Body{Vec3d}}(b))
            break
        end
    end
end

function init_grid(box::Array{Grid{T}}, bs::Vector{Body{T}}) where {T}
    Threads.@threads for i in bs
        push_grid(box, i)
    end
    update_grid(box)
end

Base.show(io::IO, grid::Grid{T}) where T = println(io, "Grid: Origin: ", grid.origin, ", Op_corner: ", grid.op_corner)

const r0 = 0.15
const r02 = r0^2

function updateAccGas(a::Body{T}, b::Body{T}, gridsize::Float64) where {T}
    r = a.pos - b.pos
    rlensqr = lensqr(r)
    if rlensqr > gridsize^2
        return
    end
    runitsqr = rlensqr / r02
    f = 24(2 / runitsqr^7 - 1 / runitsqr^4) / r0
    add(a.acc, f * r)
end

function apply(box::Array{Grid{T}}, b::Body{T}, gridsize::Float64) where {T}
    grid = box[b.tag]
    len = length(box)
    current = grid.elements.next
    while current !== grid.elements
        if current.val !== b
            updateAccGas(b, current.val, gridsize)
        end
        current = current.next
    end

    for i in strides(box)
        n = b.tag
        upper = n + i
        lower = n - i
        if upper <= len
            grid = box[upper]
            current = grid.elements.next
            # showloop(stdout, current)
            # println()
            while current !== grid.elements
                updateAccGas(b, current.val, gridsize)
                current = current.next
            end
        end

        if lower >= 1
            grid = box[lower]
            current = grid.elements.next
            while current !== grid.elements
                updateAccGas(b, current.val, gridsize)
                current = current.next
            end
        end
    end
end

function cycle_leapfrog_grid(box::Array{Grid{T}}, bodies::Vector{Body{T}}, dt::Float64, size::Float64, gridsize::Float64) where {T}
    Threads.@threads for i in bodies
        updatePos(i, 0.5dt)
    end

    check_grid(box)

    update_grid(box)

    Threads.@threads for i in bodies
        apply(box, i, gridsize)
    end

    Threads.@threads for i in bodies
        updateVel(i, dt)
    end

    Threads.@threads for i in bodies
        updatePos(i, 0.5dt)
    end
end

end
