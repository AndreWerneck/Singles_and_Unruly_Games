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
      
# when a cell value = 1 -> this cell is masked 
# so we need to see if the nodes that are equal to 0 are connected
# verifying connexity 
function is_connected(y::Array{Int64,2})
    n = size(y,1)
    need_tobe_visited_nodes = []
    visited_nodes = Set{Tuple{Int64,Int64}}()

    i,j = Tuple(findfirst(y .!= 1)) # find the first 0 of the matrix

    # add the node to be visited

    push!(need_tobe_visited_nodes,(i,j))

    #dfs algorithm
    while !isempty(need_tobe_visited_nodes) #while we still have nodes to be visited
        node = pop!(need_tobe_visited_nodes) # starts by the first node
        if !(node in visited_nodes) # if the node is not yet visited
            push!(visited_nodes,node) # we add it to the visited ones
            push_neighbors(node,y,need_tobe_visited_nodes) # we add its neighbors to be visited
        end
    end

    return length(visited_nodes)==sum(y .!= 1) # check if the visited nodes are all the nodes different than 1 in the matrix

end

function push_neighbors(node::Tuple{Int,Int}, y :: Array{Int64,2},neighbors_list)
    n = size(y,1)
    i,j = node

    if i > 1 && y[i-1,j] == 0 # upper neighbor
        push!(neighbors_list,(i-1,j))
    end
    
    if i < n && y[i+1,j] == 0 #lower neighbor
        push!(neighbors_list,(i+1,j))
    end

    if j > 1 && y[i,j-1] == 0 #left neighbor
        push!(neighbors_list,(i,j-1))
    end

    if j < n && y[i,j+1] == 0 # right neighbor
        push!(neighbors_list,(i,j+1))
    end
end

