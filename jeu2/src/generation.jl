# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")
using Random

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64, density::Float64)

    initial_matrix = generate_non_repetable_matrix(n)
    solution = generate_solution(n, density)

    for i in 1:n
        for j in 1:n
            if solution[i, j] == 1
                if initial_matrix[i,j] != n
                    initial_matrix[i,j] += 1
                else
                    initial_matrix[i,j] = 1
                end
            end
        end
    end

    return initial_matrix

end


function generate_non_repetable_matrix(n::Int64)

    t = zeros(Int64, n, n) # Initialize matrix with zeros

    for i in 1:n
        for j in 1:n
            if i == 1
                t[i,j] = j
            elseif i>1 && j == n
                t[i,1] = t[i-1,n]
            end
            
            if i>1 && j>1
                t[i,j] = t[i-1,j-1]
            end 
        end
    end

    #permuter les lignes et les colones
    lines_idx = randperm(n)
    cols_idx = randperm(n)
    
    t = t[lines_idx,:]
    t = t[:,cols_idx]



    return t
end

# generates a function of zeros and ones that respects all the three constraints 
function generate_solution(n::Int64, density::Float64)
    
    quantity_to_mark = round(n*n*density)

    solution_matrix = zeros(Int64,n,n)

    aux_matrix = copy(solution_matrix)

    count = 1
    aux = 1

    lines_vec = [elem for elem in 1:n]
    cols_vec = [elem for elem in 1:n]

    while((count <= quantity_to_mark - 1))

        if (length(lines_vec) == 0) && (length(cols_vec) == 0)
            lines_vec = [elem for elem in 1:n]
            cols_vec = [elem for elem in 1:n]
        end

        #takes a random index of the matrix
        i,j = splice!(lines_vec,rand(1:length(lines_vec))),splice!(cols_vec,rand(1:length(cols_vec)))

        solution_matrix[i,j] = 1

        # println(aux)
        # println(aux > 512)
        aux += 1
        x = 100*n

        if (aux >= x )
            solution_matrix = zeros(Int64,n,n)
            aux = 1
        end
        
        if check_adjacency(solution_matrix) && is_connected(solution_matrix)
            count = length(findall(x->x === 1, solution_matrix))
            # print(count)
            aux_matrix = copy(solution_matrix)
        else
            solution_matrix = copy(aux_matrix)
        end
    end
    return solution_matrix
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # For each grid size considered
    for size in [5,8,10,12,14,16]

        # For each grid density considered
        for density in 0.2:0.05:0.3

            # Generate 10 instances
            for instance in 1:5

                fileName = "../data/instance_t" * string(size) * "_d" * string(density) * "_" * string(instance) * ".txt"

                if !isfile(fileName)
                    println("-- Generating file " * fileName)
                    saveInstance(generateInstance(size, density), fileName)
                end 
            end
        end
    end

end



