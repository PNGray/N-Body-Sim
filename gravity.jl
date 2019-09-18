push!(LOAD_PATH, pwd())
using Vec_lib
using Body_lib
using Tree_lib
using Printf

const G = 4(π^2)
const dt = 0.001
const theta = 0.3
const pad = 5.0 * r0

mutable struct Pair{T}
    a::Body{T}
    b::Body{T}
    x_last::Float64
    t_last::Float64
    T::Float64
    halfs::Bool
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

function calculate_energy_gravity(bodies::Vector{Body{T}}) where {T}
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
    elseif outfilename == "null"
        outfile = devnull
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
    step_num = parse(Int, ARGS[4])
    size = parse(Float64, ARGS[5])

    tree::Tree{T} = Tree{T}(T(-size / 2), size, Vector{Tree{T}}(), nothing)

    n = convert(Int, div(size, pad))
    origin = T(-size / 2)

    earth_sun = Pair(bodies[1], bodies[2], -1.0, 0.0, 0.0, false)
    e = 0
    # e = calculate_energy_gravity(bodies)
    # e0 = e

    for j in bodies
        show(outfile, j)
        write(outfile, "\n")
    end
    @printf(outfile, "T -0.8 0.8\nt = 0")
    @printf(outfile, "\tenergy = %e", e)
    @printf(outfile, "\tperiod = %f\n", earth_sun.T)
    write(outfile, "F\n")
    flush(outfile)

    ex = false
    for i in 1:step_num
        t = i * dt
        cycle_leapfrog_tree(tree, bodies, dt, G, theta, size)
        # period_check(earth_sun, t)
        if i % 100 == 0
            # e = calculate_energy_gravity(bodies)
            # @printf("%f %e %f\n", t, (e0 - e), earth_sun.T)
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

        if ex == true
            break
        end

    end
end

println(ARGS)
println(pwd())
if length(ARGS) == 0
    println("infile outfile dim iterations")
else
    @time main()
end
