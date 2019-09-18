push!(LOAD_PATH, pwd())
using Vec_lib
using Grid_lib
using InteractiveUtils
using Printf

const pad = 5.0 * r0
const dt = 0.001
const halfdt = dt / 2
function generate3d(infile::IO)::Tuple{Vector{Vec3d}, Vector{Vec3d}, Vector{Vec3d}}
    str = read(infile, String)
    list = map(x->split(x, " "), split(str, "\n"))
    T = Vec3d
    pos::Vector{T} = []
    vel::Vector{T} = []
    acc::Vector{T} = []
    for i in 1:length(list)
        if length(list[i]) < 7 continue end
        elems = map(x->parse(Float64, x), list[i])
        p = Vec3d(elems[1], elems[2], elems[3])
        v = Vec3d(elems[4], elems[5], elems[6])
        mass = elems[7]
        push!(pos, p)
        push!(vel, v)
        push!(acc, Vec3d(0))
    end
    (pos, vel, acc)
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
    pos::Vector{Vec3d} = []
    vel::Vector{Vec3d} = []
    acc::Vector{Vec3d} = []
    (pos, vel, acc)::Tuple{Vector{Vec3d}, Vector{Vec3d}, Vector{Vec3d}} = generate3d(infile)
    step_num = parse(Int, ARGS[4])
    size = parse(Float64, ARGS[5])

    n = convert(Int, div(size, pad))
    gridsize = size / n
    origin = T(-size / 2)
    box::Array{Grid{Int64}, num_dim(T)} = make_box(Int64, size, n)
    init_grid(box, pos, gridsize, origin)
    for j in pos
        println(outfile, "c3 ", j.x, " ", j.y, " ", j.z, " ", r0)
    end
    println(outfile, "T -0.8 0.8\nt = 0")
    println(outfile, "F")
    println()
    flush(outfile)

    ind = eachindex(pos)
    for i in 1:step_num
        t = i * dt

        Threads.@threads for i in ind
            add(pos[i], halfdt * vel[i])
        end

        check_grid(box, pos, gridsize, origin)

        update_grid(box)

        Threads.@threads for i in ind
            apply(box, i, pos, acc, gridsize, origin)
        end

        Threads.@threads for i in ind
            l = len(pos[i])
            bound = size / 2 - 1
            if l > bound
                add(acc[i], 50000 * (bound - l) / l * pos[i])
                mul(vel[i], 0.9)
            end
        end

        Threads.@threads for i in ind
            mul(acc[i], dt)
            vel[i] += acc[i]
            reset(acc[i])
        end

        Threads.@threads for i in ind
            add(pos[i], halfdt * vel[i])
        end

        if i % 100 == 0
            println(i)
            for j in pos
                println(outfile, "c3 ", j.x, " ", j.y, " ", j.z, " ", r0)
            end

            @printf(outfile, "T -0.8 0.8\nt = %.2f\n", t)
            println(outfile, "F")
            flush(outfile)
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
