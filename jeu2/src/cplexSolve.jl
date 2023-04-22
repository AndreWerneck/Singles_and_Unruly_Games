# File with cplexSolve function

using CPLEX, JuMP

include("graph.jl")

function cplexSolve(matrix::Array{Int, 2})
    # Create the model
    m = JuMP.Model(CPLEX.Optimizer)

    n = size(matrix, 1)

    # x[i, j, k] = 1 if cell (i, j) has value k
    x = zeros(Bool, n, n, n)
    for i in 1:n
        for j in 1:n
            if matrix[i, j] != 0
                x[i, j, matrix[i, j]] = 1
            end
        end
    end

    # Create position matrix (instructions in graph.jl)
    position_matrix = create_position_matrix(n)

    # v[i, j] = 0 if not mask, 1 if mask
    @variable(m, v[1:n, 1:n], Bin)

    # variable diff (used to differentiate no connected results)
    @variable(m, diff[1:n, 1:n], Bin)

    # Each line i has one cell with value k
    @constraint(m, [k in 1:n, i in 1:n], sum(x[i, j, k] * (1 - v[i, j]) for j in 1:n) <= 1)

    # Each column j has one cell with value k
    @constraint(m, [k in 1:n, j in 1:n], sum(x[i, j, k] * (1 - v[i, j]) for i in 1:n) <= 1)

    # Black squares cannot be adjacent
    @constraint(m, [i in 1:n, j in 1:n - 1], v[i, j] + v[i, j + 1] <= 1)

    @constraint(m, [i in 1:n, j in 2:n], v[i, j] + v[i, j - 1] <= 1)

    @constraint(m, [i in 1:n - 1, j in 1:n], v[i, j] + v[i + 1, j] <= 1)

    @constraint(m, [i in 2:n, j in 1:n], v[i, j] + v[i - 1, j] <= 1)

    # Finite amount of connectivity constraints
    for i in 1:n
        for j in 1:n 
            # Corner constraints
            if value(position_matrix[i, j]) == 1
                @constraint(m, v[i, j + 1] + v[i + 1, j] <= 1)
            end
            if value(position_matrix[i, j]) == 3
                @constraint(m, v[i, j - 1] + v[i + 1, j] <= 1)
            end
            if value(position_matrix[i, j]) == 5
                @constraint(m, v[i - 1, j] + v[i, j - 1] <= 1)
            end
            if value(position_matrix[i, j]) == 7
                @constraint(m, v[i, j + 1] + v[i - 1, j] <= 1)
            end

            # Side constraints
            if value(position_matrix[i, j]) == 2
                @constraint(m, v[i, j - 1] + v[i, j + 1] + v[i + 1, j] <= 2)
            end
            if value(position_matrix[i, j]) == 4
                @constraint(m, v[i - 1, j] + v[i + 1, j] + v[i, j - 1] <= 2)
            end
            if value(position_matrix[i, j]) == 6
                @constraint(m, v[i, j - 1] + v[i, j + 1] + v[i - 1, j] <= 2)
            end
            if value(position_matrix[i, j]) == 8
                @constraint(m, v[i - 1, j] + v[i + 1, j] + v[i, j + 1] <= 2)
            end

            # Center constraint
            if value(position_matrix[i, j]) == 0
                @constraint(m, v[i - 1, j] + v[i + 1, j] + v[i, j + 1] + v[i, j - 1] <= 3)
            end
        end
    end

    # Variable to verify if the final table is connected
    solved = false
    
    # Count iterations
    count_c = 0

    # Maximize 1
    @objective(m, Max, 1)

    # timer
    start = time()
    
    # While solved == false, add the v_old constraint (the new table must be different)
    v_old = zeros(Bool, n, n)
    while solved == false
        optimize!(m)
        solved = is_connected(converted_to_array(v))
        if solved == true
            return v, time() - start, JuMP.primal_status(m) == MOI.FEASIBLE_POINT
        end
        if solved == false
            for i in 1:n
                for j in 1:n
                    v_old[i,j] = value(v[i,j])
                end
            end
            @constraint(m, sum(v[i,j] for i in 1:n for j in 1:n if v_old[i,j]==1) <= sum(v_old[i,j] for i in 1:n for j in 1:n) - 1)
            count_c = count_c + 1
        end
    end

end




