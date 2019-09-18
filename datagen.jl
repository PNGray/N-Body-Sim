push!(LOAD_PATH, pwd())
using Vec_lib
using Body_lib
using Printf

getmass(r::Float64) = (r / 0.15)^3
function main()
    bodies::Vector{Body{Vec3d}} = []
    if length(ARGS) >= 5
        for i in 5:(length(ARGS))
            append!(bodies, generate3d(open(ARGS[i], "r")))
        end
    end
    n = parse(Int, ARGS[1])
    size = parse(Float64, ARGS[2])
    jiggle = parse(Float64, ARGS[3])
    mass = getmass(parse(Float64, ARGS[4]))
    for i in 1:n
        T = Float64

        vec = Vec3d(randn(T), randn(T), randn(T))
        veclen = len(vec)
        mul(vec, 1 / veclen)

        r = size * ((rand(T))^(1 / 3))
        mul(vec, r)

        vecflat = Vec2d(vec.x, vec.y)

        trans = 0.0
        vl = trans * vecflat / len(vecflat)
        add(vec, vl)
        add(vecflat, vl)

        vel = Vec2d(-vec.y, vec.x)

        # avg = size / 2 + trans
        # mul(vel, 1 / len(vecflat)^(1.5 + (avg - len(vecflat)) / 75size))
        mul(vel, 0000.0^0.5)

        vel += jiggle * Vec2d(randn(T), randn(T))
        z = jiggle * randn(T)
        vec.z += 1.1size
        push!(bodies, Body(vec, Vec3d(vel.x, vel.y, z), Vec3d(0.0, 0.0, 0.0), mass, 1))
        #println("$(vec.x) $(vec.y) $(vec.z) $(vel.x) $(vel.y) $z 0.08")
    end


    for i in bodies
        if i.tag == 0 continue end
        for j in bodies
            d = dist(i.pos, j.pos)
            if d < 1.3(radius(i) + radius(j)) && d > 0
                if j.tag != 2
                  j.tag = 0
                end
            end
        end
    end

    for i in bodies
        if i.tag == 0
            continue
        else
            println("$(i.pos.x) $(i.pos.y) $(i.pos.z) $(i.vel.x) $(i.vel.y) $(i.vel.z) 1")
        end
    end
end

main()
