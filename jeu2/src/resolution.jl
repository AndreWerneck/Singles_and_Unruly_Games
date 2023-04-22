# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
include("cplexSolve.jl")
include("generation.jl")

TOL = 0.00001

"""
Heuristically solve an instance
"""
function heuristicSolve(t::Array{Int64,2})

    n = size(t,1)

    y = zeros(Int64,n,n) # binary matrix of masks

    x = zeros(Int64,n,n,n) # vector to check duplicate values

    for i in 1:n
        for j in 1:n
            x[i,j,t[i,j]] = 1 # set 1 for a cell at the k index that has the k value
        end
    end

    solved = solverec(t,y,1,1)

    if((solved == true) && (check_repeated_values(x,y) == true))
        # displaySolution(t,y)
        return solved,y
    else
        ("There is no solution")
        return solved,-1
    end
end

function solverec(board::Array{Int64,2},y::Array{Int64,2} ,line :: Int64, col :: Int64)
    # creates a copy of the original board
    t = copy(board)

    n = size(t,1)

    if (line == n) && (col == n)
        return true
    end

    # if it is already marked
    if t[line,col] == 0
        #goes to next number in line or goes to first number of next line    
        if (col + 1) > n
            return (solverec(t,y,(line + 1), 1))
        else
            return (solverec(t,y,line, (col + 1)))
        end  
    end

    element = t[line,col]
    rep_inline_list = findall(x->x === element,t[line,:])
    rep_incol_list = findall(x->x === element, t[:,col])

    if ( (length(rep_inline_list) == 1) && (length(rep_incol_list) == 1) )
        #goes to next number in line or goes to first number of next line
        if (col + 1) > n
            return (solverec(t,y,(line + 1), 1))
        else
            return (solverec(t,y,line, (col + 1)))
        end
    end

    if length(rep_inline_list)>1
        for elem_col in rep_inline_list
            # mark all the repeated elements in line and column excpet the one in [line,col]
            # marks also at the solution binary matrix
            mark_elements(t,y,line,elem_col,element)

            #check the adjacency
            adjacency_ok = check_adjacency(y)

            #check connexity
            connexity_ok = is_connected(y)

            if( (adjacency_ok == true) && (connexity_ok == true) )
                #goes to next number in line or goes to first number of next line
                if (col+1)>n
                    is_good_solution = solverec(t,y,line + 1,1)
                else
                    is_good_solution = solverec(t,y,line,col+1)
                end
                
                if (is_good_solution == false)
                    restore_elements(board,t,y,line,elem_col,element)
                end

                if(is_good_solution==true)
                    return true
                end

            else
                restore_elements(board,t,y,line,elem_col,element)
            end

        end
    end


    if length(rep_incol_list)>1
        for elem_line in rep_incol_list
            # mark all the repeated elements in line and column excpet the one in [line,col]
            # marks also at the solution binary matrix
            mark_elements(t,y,elem_line,col,element)

            #check the adjacency
            adjacency_ok = check_adjacency(y)

            #check connexity
            connexity_ok = is_connected(y)

            #check repeated values
            # repeated_values_ok = check_repeated_values(x,y)


            if( (adjacency_ok == true) && (connexity_ok == true) )
                #goes to next number in line or goes to first number of next line
                if (col+1)>n
                    is_good_solution = solverec(t,y,line + 1,1)
                else
                    is_good_solution = solverec(t,y,line,col+1)
                end
                
                if (is_good_solution == false)
                    restore_elements(board,t,y,elem_line,col,element)
                end

                if(is_good_solution==true)
                    return true
                end

            else
                restore_elements(board,t,y,elem_line,col,element)
            end

        end
    end

    return false

end

function restore_elements(t_original::Array{Int64,2},t_copy::Array{Int64,2},y_copy::Array{Int64,2},line::Int64,col::Int64,element::Int64)

    for j in 1:length(t_copy[line,:])
    # restoring repeated elements in line except the current one
        if j != col && t_original[line,j] == element
            t_copy[line,j] = element
            y_copy[line,j] = 0
        end
    # restoring repeated elements in columns except the current one
        if j != line && t_original[j,col] == element
            t_copy[j,col] = element
            y_copy[j,col] = 0
        end

    end

end

function mark_elements(t::Array{Int64,2}, sol_matrix::Array{Int64,2},line::Int64,col::Int64,element::Int64)

    for j in 1:length(t[line,:])
    # marking repeated elements in line except the current one
        if j != col && t[line,j] == element
            t[line,j] = 0
            sol_matrix[line,j] = 1
        end
    # marking repeated elements in columns except the current one
        if j != line && t[j,col] == element
            t[j,col] = 0
            sol_matrix[j,col] = 1
        end

    end
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
        !all((y[i,j] + y[i-1,j]) <= 1 for i in 2:n for j in 1:n) )  # check if adjacent cells are not masked at the same time
        
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

    #depth first search algorithm
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

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    # resolutionMethod = ["cplex"]
    resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        t = readInputFile(dataFolder * file)
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # Solve it and get the results
                    v,resolutionTime,isOptimal = cplexSolve(t)
                    
                    # If a solution is found, write it
                    if isOptimal
                        writeSolution(fout, converted_to_array(v))
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false
                    solution = []

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # Solve it and get the results
                        isOptimal, solution = heuristicSolve(t)

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal
                        writeSolution(fout, solution)
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
