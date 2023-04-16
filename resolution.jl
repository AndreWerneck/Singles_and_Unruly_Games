using LightGraphs
"""
Heuristically solve an instance
"""
function heuristicSolve(t::Array{Int64,2})

    n = size(t,1)  
end

# check first constraint
function check_repeated_values(x::Array{Int64,3},y::Array{Int64,2})
    n = size(x,1)

    if (!all(sum(x[i,j,k] * (1 - y[i,j]) for j in 1:n) <= 1 for i in 1:n for k in 1:n) #checking repeated numbers in lines
        || !all(sum(x[i,j,k] * (1 - y[i,j]) for i in 1:n) <= 1 for j in 1:n for k in 1:n)) #checking repeated numbers in columns
        
        return false
    else
        return true
    end
end

#check second constraint

function check_adjacency(y::Array{Int64,2})
    n = size(y,1)

    if ( !all((y[i,j] + y[i,j+1]) <= 1 for i in 1:n for j in 1:(n-1)) || # check if adjacent cells are not masked at the same time
        !all((y[i,j] + y[i,j-1]) <= 1 for i in 1:n for j in 2:n) || # check if adjacent cells are not masked at the same time
        !all((y[i,j] + y[i+1,j]) <= 1 for i in 1:(n-1) for j in 1:n) || # check if adjacent cells are not masked at the same time
        !all((y[i,j] + y[i-1,j]) <= 1 for i in 1:n for j in 1:n) )  # check if adjacent cells are not masked at the same time
        
        return false
    else
        return true
    end
end
        
function is_connected(matrix::Array{Int64,2})
    n = size(matrix, 1)
    visited = zeros(Bool, n)
    stack = [1]  # Start from node 1 (can be any node)
    visited[1] = true

    # Perform depth-first search
    while !isempty(stack)
        node = pop!(stack)
        for i in 1:n
            if matrix[node, i] == 1 && !visited[i]
                push!(stack, i)
                visited[i] = true
            end
        end
    end

    # Check if all nodes are visited
    return all(visited)
end

function matrix_to_graph(matrix::Array{Int64,2})
    n = size(matrix, 1)
    graph = SimpleGraph(n)

    for i in 1:n
        for j in i+1:n
            if matrix[i, j] == 1
                add_edge!(graph, i, j)
            end
        end
    end

    return graph
end