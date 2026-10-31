# Lanceur autonome : julia --startup-file=no benchmark/bench.jl [--full] [--out DIR]
# Tout le pilotage et les deux bancs de mesure sont en Julia.
import Pkg

const ROOT = normpath(joinpath(@__DIR__, ".."))
const HELP = "Usage: julia benchmark/bench.jl [--quick|--full] [--out DIRECTORY]"

function options(args)
    mode = :quick
    output = joinpath(@__DIR__, "results")
    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--full"
            mode = :full
        elseif arg == "--quick"
            mode = :quick
        elseif arg == "--out"
            i < length(args) || error("--out demande un répertoire\n", HELP)
            i += 1
            output = abspath(args[i])
        elseif arg in ("--help", "-h")
            println(HELP)
            exit(0)
        else
            error("Option inconnue: $arg\n$HELP")
        end
        i += 1
    end
    return mode, output
end

mode, output = options(ARGS)
mkpath(output)

Pkg.activate(@__DIR__)
Pkg.develop(; path=ROOT)
Pkg.instantiate()

env = Dict{String,String}("GOOSE_BENCH_OUT" => output,
                           "GOOSE_STAGE_OUT" => output)
if mode == :quick
    merge!(env, Dict(
        "GOOSE_BENCH_SECONDS" => "0.05",
        "GOOSE_BENCH_SAMPLES" => "250",
        "GOOSE_BENCH_LENGTHS" => "4,64,1000",
        "GOOSE_BENCH_MATRIX_SIZES" => "2,8,16",
        "GOOSE_STAGE_LENGTHS" => "4,64,1000",
        "GOOSE_STAGE_SIDES" => "2,8,16",
        "GOOSE_STAGE_STATICGOOSE_MAX" => "1000",
    ))
end

for script in ("run.jl", "staged.jl")
    command = `$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$(joinpath(ROOT, "benchmark")) $(joinpath(@__DIR__, script))`
    println("\n[GooseArrays] $mode — $script — résultats : $output")
    flush(stdout)
    run(addenv(command, env))
end
println("\nTerminé : ", joinpath(output, "benchmarks.csv"), " et ", joinpath(output, "staged.csv"))
