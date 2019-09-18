module Grid_lib

using Vec_lib
using Body_lib
using Linked_list
using Printf

export Grid, check_grid, update_grid, make_box, init_grid, cycle_leapfrog_grid, r0, apply

mutable struct Grid{T}
    elements::Link{T}
    buffer::Vector{Link{T}}
    buffered::Bool
    Grid{T}() where {T} = begin
        x = new{T}(Link{T}(), Vector{Link{T}}(), false)
        for i in 1:Threads.nthreads()
            push!(x.buffer, Link{T}())
        end
        return x
    end
end

function getzone(pos::Vec3d, n::Int64, gridsize::Float64, origin::Vec3d)::Int
    v = pos - origin
    (a, b, c) = (1, n, n * n)
    resx = floor(v.x / gridsize)
    resy = floor(v.y / gridsize)
    resz = floor(v.z / gridsize)
    resx = min(resx, b - 1)
    resy = min(resy, b - 1)
    resz = min(resz, b - 1)
    resx = max(resx, 0)
    resy = max(resy, 0)
    resz = max(resz, 0)
    n = 1 + a * resx + b * resy + c * resz
    n
end

function check_grid(box::Array{Grid{Body{Vec3d}}, 3}, gridsize::Float64, origin::Vec3d)
    (sx, sy, sz) = strides(box)
    Threads.@threads for n in eachindex(box)
        threadid = Threads.threadid()
        grid = box[n]
        current = grid.elements.next
        while !(current === grid.elements)
            next = current.next
            new = getzone(current.val.pos, sy, gridsize, origin)
            if new != n
                remove_link(current)
                new_grid = box[new]
                current.val.tag = new
                push_link(new_grid.buffer[threadid], current)
                new_grid.buffered = true
            end
            current = next
        end
    end
    return
end

function check_grid(box::Array{Grid{Int64}, 3}, pos::Vector{Vec3d}, gridsize::Float64, origin::Vec3d)
    (sx, sy, sz) = strides(box)
    Threads.@threads for n in eachindex(box)
        threadid = Threads.threadid()
        grid = box[n]
        current = grid.elements.next
        while !(current === grid.elements)
            next = current.next
            new = getzone(pos[current.val], sy, gridsize, origin)
            if new != n
                remove_link(current)
                new_grid = box[new]
                push_link(new_grid.buffer[threadid], current)
                new_grid.buffered = true
            end
            current = next
        end
    end
    return
end

function update_grid(box::Array{Grid{T}}) where {T}
    Threads.@threads for n in box
        if n.buffered
            n.buffered = false
            for i in n.buffer
                concat(n.elements, i)
            end
        end
    end
    return
end

function make_box(T::DataType, size::Float64, n::Int64)::Array{Grid{T}, 3}
    pad = size / n
    box = Array{Grid{T}}(undef, n, n, n)
    for k in 1:n
        for j in 1:n
            for i in 1:n
                box[i, j, k] = Grid{T}()
            end
        end
    end
    box
end

function init_grid(box::Array{Grid{Body{T}}}, bs::Vector{Body{T}}, gridsize::Float64, origin::T) where {T}
    Threads.@threads for i in bs
        zone = getzone(i.pos, size(box, 1), gridsize, origin)
        grid = box[zone]
        i.tag = zone
        push_link(grid.buffer[Threads.threadid()], Link{Body{T}}(i))
        grid.buffered = true
    end
    update_grid(box)
    return
end

function init_grid(box::Array{Grid{Int64}}, pos::Vector{Vec3d}, gridsize::Float64, origin::Vec3d)
    Threads.@threads for i in eachindex(pos)
        zone = getzone(pos[i], size(box, 1), gridsize, origin)
        grid = box[zone]
        push_link(grid.buffer[Threads.threadid()], Link{Int64}(i))
        grid.buffered = true
    end
    update_grid(box)
    return
end

Base.show(io::IO, grid::Grid{T}) where T = println(io, "Grid: ", pointer_from_objref(grid))

const r0 = 0.15
const r02 = r0^2

function updateAccGas(a::Body{T}, b::Body{T}, gridsize::Float64) where {T}
    r = a.pos - b.pos
    rlensqr = lensqr(r)
    if rlensqr > gridsize^2
        return
    end
    runitsqr = rlensqr / r02
    runit6 = runitsqr * runitsqr * runitsqr
    runit8 = runit6 * runitsqr
    runit14 = runit6 * runit8
    f = 24(2 / runit14 - 1 / runit8) / r0
    add(a.acc, f * r)
    return
end

function updateAccGas(p1::Vec3d, a::Vec3d, p2::Vec3d, gridsize::Float64)
    r = p1 - p2
    rlensqr = lensqr(r)
    if rlensqr > gridsize * gridsize
        return
    end
    runitsqr = rlensqr / r02
    runit6 = runitsqr * runitsqr * runitsqr
    runit8 = runit6 * runitsqr
    runit14 = runit6 * runit8
    f = 24(2 / runit14 - 1 / runit8) / r0
    add(a, f * r)
    return
end

function apply_grid(grid::Grid{T}, b::T, gridsize::Float64) where {T}
    current = grid.elements.next
    while current !== grid.elements
        if current.val !== b
          updateAccGas(b, current.val, gridsize)
        end

        current = current.next
    end
    return
end

function apply_grid(grid::Grid{Int64}, i::Int64, ps::Vector{Vec3d}, as::Vector{Vec3d}, gridsize::Float64)
    current = grid.elements.next
    while current !== grid.elements
        if current.val !== i
          updateAccGas(ps[i], as[i], ps[current.val], gridsize)
        end

        current = current.next
    end
    return
end

function apply(box::Array{Grid{Body{Vec3d}}, 3}, b::Body{Vec3d}, gridsize::Float64)
    len = length(box)
    n = b.tag
    (x, y, z) = strides(box)
    for k in -1:1
        for j in -1:1
            for i in -1:1
                n_current = n + x * i + y * j + z * k
                if n_current >=1 && n_current <= len
                    apply_grid(box[n_current], b, gridsize)
                end
            end
        end
    end
    return
end

function apply(box::Array{Grid{Int64}, 3}, n::Int64, ps::Vector{Vec3d}, as::Vector{Vec3d}, gridsize::Float64, origin::Vec3d)
    len = length(box)
    (x, y, z) = strides(box)
    n = getzone(ps[n], y, gridsize, origin)
    for k in -1:1
        for j in -1:1
            for i in -1:1
                n_current = n + x * i + y * j + z * k
                if n_current >=1 && n_current <= len
                    apply_grid(box[n_current], n, ps, as, gridsize)
                end
            end
        end
    end
    return
end

function cycle_leapfrog_grid(box::Array{Grid{T}}, bodies::Vector{T}, dt::Float64, size::Float64, gridsize::Float64, origin::Vec3d) where {T}
    Threads.@threads for i in bodies
        updatePos(i, 0.5dt)
    end

    check_grid(box, gridsize, origin)

    update_grid(box)

    Threads.@threads for i in bodies
        apply(box, i, gridsize)
    end

    Threads.@threads for i in bodies
        l = len(i.pos)
        bound = size / 2 - 1
        if l > bound
            add(i.acc, 50000 * (bound - l) / l * (i.pos))
            mul(i.vel, 0.9)
        end
    end

    Threads.@threads for i in bodies
        updateVel(i, dt)
    end

    Threads.@threads for i in bodies
        updatePos(i, 0.5dt)
    end
    return
end

end
