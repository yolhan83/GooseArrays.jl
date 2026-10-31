# Regenerate the README and Documenter benchmark tables from one CSV campaign.
# No third-party packages are required.
using Printf

const ROOT = normpath(joinpath(@__DIR__, ".."))
const REFERENCE = joinpath(@__DIR__, "reference", "m5-max-2026-10-31")
const FAMILIES = ["Array", "FixedSizeArray", "GooseArray", "StaticGooseArray", "MVector"]
const FAMILY_LABELS = ["Vector", "FixedSizeVector", "GooseVector", "StaticGooseVector", "MVector"]

# Small CSV reader supporting quoted fields (needed for specialization.csv's type names).
function csv_fields(line::AbstractString)
    fields = String[]
    buffer = IOBuffer()
    quoted = false
    chars = collect(line)
    i = 1
    while i <= length(chars)
        c = chars[i]
        if c == '"'
            if quoted && i < length(chars) && chars[i + 1] == '"'
                print(buffer, '"')
                i += 1
            else
                quoted = !quoted
            end
        elseif c == ',' && !quoted
            push!(fields, String(take!(buffer)))
        else
            print(buffer, c)
        end
        i += 1
    end
    quoted && error("Unterminated quoted CSV field: $line")
    push!(fields, String(take!(buffer)))
    return fields
end

function load_csv(path)
    isfile(path) || error("Missing CSV: $path")
    lines = readlines(path)
    isempty(lines) && error("Empty CSV: $path")
    headers = csv_fields(first(lines))
    rows = Dict{String,String}[]
    for line in Iterators.drop(lines, 1)
        isempty(strip(line)) && continue
        fields = csv_fields(line)
        length(fields) == length(headers) || error("Malformed CSV row in $path: $line")
        push!(rows, Dict(zip(headers, fields)))
    end
    return rows
end

function index_results(rows)
    result = Dict{Tuple{String,Int,String},Dict{String,String}}()
    for row in rows
        key = (row["family"], parse(Int, row["n"]), row["operation"])
        haskey(result, key) && error("Duplicate benchmark entry: $key")
        result[key] = row
    end
    result
end

function format_cell(results, family, n, op)
    row = get(results, (family, n, op), nothing)
    isnothing(row) && return "—"
    return @sprintf("%.1f / %d", parse(Float64, row["median_ns"]), parse(Int, row["gc_bytes"]))
end

function markdown_table(header, rows; left_columns=2)
    widths = [i <= left_columns && i != 1 ? "---" : "---:" for i in eachindex(header)]
    out = String["| " * join(header, " | ") * " |",
                 "| " * join(widths, " | ") * " |"]
    append!(out, ["| " * join(row, " | ") * " |" for row in rows])
    join(out, "\n")
end

function comparison_table(results, entries; labels=FAMILY_LABELS, families=FAMILIES, first_label="Size")
    rows = Vector{String}[]
    for (size, n, label, op) in entries
        cells = [format_cell(results, family, n, op) for family in families]
        push!(rows, [size, label, cells...])
    end
    markdown_table([first_label, "Operation", labels...], rows)
end

function rows_for(results, operations)
    sizes = sort!(unique([n for (family, n, op) in keys(results)
                          if family in FAMILIES && op in first.(operations)]))
    [(string(n), n, label, op) for n in sizes for (op, label) in operations]
end

function matrix_rows_for(results, operations)
    sizes = sort!(unique([n for (family, n, op) in keys(results)
                          if family in FAMILIES && op in first.(operations)]))
    [("$(n)×$(n)", n, label, op) for n in sizes for (op, label) in operations]
end

function svector_table(results)
    ops = ["sum", "mapreduce", "map_then_sum", "broadcast_then_sum"]
    sizes = sort!(unique([n for (family, n, op) in keys(results) if family == "SVector" && op in ops]))
    rows = [[string(n), (format_cell(results, "SVector", n, op) for op in ops)...] for n in sizes]
    markdown_table(["n", "SVector sum", "SVector abs2 reduction", "SVector map then sum",
                    "SVector broadcast then sum"], rows; left_columns=1)
end

function specialization_table(rows)
    families = ["Array", "FixedSizeArray", "GooseArray", "StaticGooseArray", "MVector", "SVector"]
    output = Vector{String}[]
    for family in families
        group = [row for row in rows if row["family"] == family]
        isempty(group) && continue
        sort!(group, by=row -> parse(Int, row["n"]))
        count_types = length(Set(row["array_type"] for row in group))
        count_instances = group[end]["method_instances"]
        total_ms = sum(parse(Float64, row["compile_seconds"]) for row in group) * 1000
        push!(output, [family, string(length(group)), string(count_types), count_instances,
                       @sprintf("%.3f", total_ms)])
    end
    markdown_table(["Family", "Shapes tested", "Concrete types", "Final kernel instances",
                    "Cumulative kernel compilation (ms)"], output; left_columns=1)
end

function make_tables(directory)
    basic = index_results(load_csv(joinpath(directory, "benchmarks.csv")))
    staged = index_results(load_csv(joinpath(directory, "staged.csv")))
    specialization_file = joinpath(directory, "specialization.csv")
    specialization = isfile(specialization_file) ? load_csv(specialization_file) : nothing
    isnothing(specialization) && @warn "No specialization.csv in the selected campaign; keeping the existing specialization table"

    readme = [("4", 4, "`sum(map(f,x))`", "map_then_sum"),
              ("64", 64, "`sum(map(f,x))`", "map_then_sum"),
              ("1,000", 1000, "`sum(map(f,x))`", "map_then_sum"),
              ("10,000", 10000, "`sum(map(f,x))`", "map_then_sum"),
              ("64", 64, "`mapreduce(abs2,+,x)`", "mapreduce"),
              ("1,000", 1000, "`sum(f.(x))`", "broadcast_then_sum")]
    first_ops = ["map!" => "in-place map!",
                 "map_then_sum" => "map then sum",
                 "sum_fused" => "fused sum(f)",
                 "mapreduce" => "abs2 reduction",
                 "broadcast_update!" => "in-place broadcast",
                 "broadcast_then_sum" => "broadcast then sum",
                 "broadcast_expr_then_sum" => "2 .* b .+ 1 then sum"]
    matrix_ops = ["matrix_mul!" => "in-place mul!", "matrix_*_then_sum" => "multiply then sum"]
    staged_ops = ["map2!" => "two-input map!", "map3!" => "three-input map!",
                  "map2_then_sum" => "two-input map then sum",
                  "map3_then_sum" => "three-input map then sum",
                  "mapreduce2" => "two-input mapreduce",
                  "mapreduce3" => "three-input mapreduce",
                  "axpy!" => "axpy!", "axpby!" => "axpby!"]
    matvec_ops = ["matvec_mul!" => "matrix–vector mul!",
                  "matvec_*_then_sum" => "multiply then sum"]
    extra_ops = ["construct_escape" => "escaping construction",
                 "construct_fill_sum" => "construct + fill + sum",
                 "fill!" => "fill!", "sum" => "sum", "getindex" => "indexing",
                 "copyto!" => "copyto!", "dot" => "dot",
                 "loop_update!" => "affine loop",
                 "broadcast_expr!" => "in-place broadcast expression"]
    table = Dict{String,String}()
    table["readme"] = comparison_table(basic, readme;
        labels=["Vector", "FixedSizeArray", "GooseVector", "StaticGooseVector", "MVector"],
        first_label="n")
    table["vectors"] = comparison_table(basic, rows_for(basic, first_ops))
    table["matrices"] = comparison_table(basic, matrix_rows_for(basic, matrix_ops);
        labels=["Matrix", "FixedSizeMatrix", "GooseMatrix", "StaticGooseMatrix", "MMatrix"])
    table["multi-input"] = comparison_table(staged, rows_for(staged, staged_ops))
    table["matvec"] = comparison_table(staged, matrix_rows_for(staged, matvec_ops);
        labels=["Matrix × Vector", "FixedSizeMatrix × FixedSizeVector", "GooseMatrix × GooseVector",
                "StaticGooseMatrix × StaticGooseVector", "MMatrix × MVector"])
    table["additional"] = comparison_table(basic, rows_for(basic, extra_ops))
    table["svector"] = svector_table(basic)
    if !isnothing(specialization)
        table["specialization"] = specialization_table(specialization)
    end
    return table
end

function refresh_file(path, ids, tables; check=false)
    existing = read(path, String)
    updated = existing
    for id in ids
        if !haskey(tables, id)
            println("Skipped (no CSV): ", id)
            continue
        end
        opening = "<!-- BEGIN GENERATED BENCHMARK: $id -->"
        closing = "<!-- END GENERATED BENCHMARK: $id -->"
        left = split(updated, opening; limit=2)
        length(left) == 2 || error("Marker not found in $path: $opening")
        right = split(left[2], closing; limit=2)
        length(right) == 2 || error("Marker not found in $path: $closing")
        prefix = replace(left[1], r"\n+$" => "")
        suffix = replace(right[2], r"^\n+" => "")
        updated = string(prefix, "\n\n", opening, "\n\n",
                         tables[id], "\n\n", closing, "\n\n", suffix)
    end
    if check
        existing == updated || error("Out-of-date benchmark tables: $path. Run julia benchmark/update_tables.jl")
        println("Current: ", relpath(path, ROOT))
    elseif existing == updated
        println("Unchanged: ", relpath(path, ROOT))
    else
        write(path, updated)
        println("Updated: ", relpath(path, ROOT))
    end
end

# Reformat the existing tables without reading CSV files or changing measurements.
function existing_tables(path, ids)
    content = read(path, String)
    tables = Dict{String,String}()
    for id in ids
        opening = "<!-- BEGIN GENERATED BENCHMARK: $id -->"
        closing = "<!-- END GENERATED BENCHMARK: $id -->"
        left = split(content, opening; limit=2)
        length(left) == 2 || error("Marker not found in $path: $opening")
        right = split(left[2], closing; limit=2)
        length(right) == 2 || error("Marker not found in $path: $closing")
        tables[id] = strip(right[1])
    end
    return tables
end

function main(args)
    if args == ["--format-only"]
        readme_path = joinpath(ROOT, "README.md")
        docs_path = joinpath(ROOT, "docs", "src", "performance.md")
        readme_ids = ["readme"]
        docs_ids = ["vectors", "matrices", "multi-input", "matvec", "additional",
                    "svector", "specialization"]
        refresh_file(readme_path, readme_ids, existing_tables(readme_path, readme_ids))
        refresh_file(docs_path, docs_ids, existing_tables(docs_path, docs_ids))
        return
    end
    source = REFERENCE
    check = false
    i = 1
    while i <= length(args)
        if args[i] == "--source"
            i < length(args) || error("--source requires a directory")
            source = abspath(args[i + 1])
            i += 1
        elseif args[i] == "--check"
            check = true
        else
            error("Unknown option: $(args[i]). Use --source PATH or --check")
        end
        i += 1
    end
    tables = make_tables(source)
    refresh_file(joinpath(ROOT, "README.md"), ["readme"], tables; check)
    refresh_file(joinpath(ROOT, "docs", "src", "performance.md"),
                 ["vectors", "matrices", "multi-input", "matvec", "additional",
                  "svector", "specialization"], tables; check)
end

main(ARGS)
