include("body.jl")

const G = 1.0#4(π^2)
const dt = 0.001

mutable struct Pair{T}
    a::Body{T}
    b::Body{T}
    x_last::Float64
    t_last::Float64
    T::Float64
    halfs::Bool
end

function generate2d(infile::IO)
    str = read(infile, String)
    list = map(x->split(x, " "), split(str, "\n"))
    T = Vec2d
    bodies::Vector{Body{T}} = []
    for i in 1:length(list)
        if length(list[i]) < 5 continue end
        elems = map(x->parse(Float64, x), list[i])
        pos = Vec2d(elems[1], elems[2])
        vel = Vec2d(elems[3], elems[4])
        mass = elems[5]
        push!(bodies, Body(pos, vel, Vec2d(0.0, 0.0), mass, i))
    end
    bodies
end

function generate3d(infile::IO)
    str = read(infile, String)
    list = map(x->split(x, " "), split(str, "\n"))
    T = Vec3d
    bodies::Vector{Body{T}} = []
    for i in 1:length(list)
        if length(list[i]) < 7 continue end
        elems = map(x->parse(Float64, x), list[i])
        pos = Vec3d(elems[1], elems[2], elems[3])
        vel = Vec3d(elems[4], elems[5], elems[6])
        mass = elems[7]
        push!(bodies, Body(pos, vel, Vec3d(0.0, 0.0, 0.0), mass, i))
    end
    bodies
end

function cycle_leapfrog(tree::Tree{T}, bodies::Vector{Body{T}}, dt::Float64, theta::Float64) where {T}
    tree.children = Vector{Tree{T}}()
    tree.center = nothing
    Threads.@threads for i in bodies
        updatePos(i, 0.5dt)
    end
    for i in bodies
        push(tree, i)
    end
    Threads.@threads for i in bodies
        apply(i, tree, theta, G, dt)
    end

    Threads.@threads for i in bodies
        l = len(i.pos)
        bound = 15
        if l > bound
            add(i.acc, 50000 * (bound - l) / l * (i.pos))
        end
    end

    Threads.@threads for i in bodies
        updateVel(i, dt)
    end
    Threads.@threads for i in bodies
        updatePos(i, 0.5dt)
    end
end

function period_check(p::Pair, t::Float64)
    x = p.a.pos.x - p.b.pos.x
    v = p.a.vel.x - p.b.vel.x
    if x * p.x_last < 0
        p.x_last = x
        if p.halfs
            t_interpolate = t - v * x
            p.T = t_interpolate - p.t_last
            p.t_last = t_interpolate
        end
        p.halfs = !p.halfs
    end
end

function calculate_energy(bodies::Vector{Body{T}}) where {T}
    energy = 0
    for i in bodies
        energy += 0.5i.mass * lensqr(i.vel)
        for j in bodies
            if i == j
                continue
            end
            d = dist(i.pos, j.pos)
            energy -= G * i.mass * j.mass / d / 2
        end
    end
    energy
end

function main()
    infilename = ARGS[1]
    outfilename = ARGS[2]
    infile = open(infilename, "r")
    if outfilename == "stdout"
        outfile = Base.stdout
    else
        outfile = open(outfilename, "w")
    end
    T = parse(Int, ARGS[3]) == 2 ? Vec2d : Vec3d
    bodies::Vector{Body{T}} = []
    if parse(Int, ARGS[3]) == 2
        bodies = generate2d(infile)
    else
        bodies = generate3d(infile)
    end
    n = parse(Int, ARGS[4])
    tree = Tree{T}(T(-250.0, -250.0, -250.0), 500.0, Vector{Tree{T}}(), nothing)
    earth_sun = Pair(bodies[1], bodies[2], -1.0, 0.0, 0.0, false)
    e = 0

    for j in bodies
        show(outfile, j)
        write(outfile, "\n")
    end
    @printf(outfile, "T -0.8 0.8\nt = 0")
    @printf(outfile, "\tenergy = %e", e)
    @printf(outfile, "\tperiod = %f\n", earth_sun.T)
    write(outfile, "F\n")
    flush(outfile)

    for i in 1:n
        t = i * dt
        cycle_leapfrog(tree, bodies, dt, 0.3)
        # period_check(earth_sun, t)
        if i % 10 == 0
            # e = calculate_energy(bodies)
            println(i)
            for j in bodies
                show(outfile, j)
                write(outfile, "\n")
            end
            @printf(outfile, "T -0.8 0.8\nt = %.2f", t)
            @printf(outfile, "\tenergy = %e", e)
            @printf(outfile, "\tperiod = %f\n", earth_sun.T)
            write(outfile, "F\n")
            flush(outfile)
        end
    end
end

println(ARGS)
if length(ARGS) == 0
    println("infile outfile dim iterations")
else
    @time main()
end
