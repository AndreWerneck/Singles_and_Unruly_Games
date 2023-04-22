# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX

Argument
- t: array of size n*n with values in [0, 2] (0 if the cell is empty)

Return
- Optimal true if the problem is solved optimally
- x: 3-dimensional variables array such that x[i, j, k] = 1 if cell (i, j) has value k
- resolution time in seconds
"""
function cplexSolve(t::Array{Int, 2})

    n = size(t,1)

    # Create the model
    # m = Model(with_optimizer(CPLEX.Optimizer))
    m = JuMP.Model(CPLEX.Optimizer)

    # x[i,j,k] = 1 if cell (i,j) has color k
    @variable(m, x[1:n, 1:n, 1:2], Bin)

    # Set the fixed value in the grid
    for l in 1:n
        for c in 1:n
            if t[l,c] != 0
                @constraint(m, x[l,c,t[l,c]] == 1)
            end
        end
    end

    # only one color per position
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i,j,k] for k in 1:2) == 1)

    # each row and column contains the same number of black and white squares.
    @constraint(m, [i in 1:n, k in 1:2], sum(x[i,j,k] for j in 1:n) == n/2)
    @constraint(m, [j in 1:n, k in 1:2], sum(x[i,j,k] for i in 1:n) == n/2)

    # no three consecutive squares, horizontally or vertically, are the same colour
    @constraint(m, [i in 1:n, j in 1:(n-2), k in 1:2], x[i,j,k] + x[i,j+1,k] + x[i,j+2,k] <=2)
    @constraint(m, [i in 1:(n-2), j in 1:n, k in 1:2], x[i,j,k] + x[i+1,j,k] + x[i+2,j,k] <=2)

    @objective(m, Max, 1)

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    #return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
    return JuMP.primal_status(m) == MOI.FEASIBLE_POINT, x, time() - start
end

"""
Heuristically solve a grid by successively assigning values to one of the most constrained cells 
(i.e., a cell in which the number of remaining possible values is the lowest)

Argument
- t: array of size n*n with values in [0, 2] (0 if the cell is empty)

Return
- gridFeasible: true if the problem is solved
- tCopy: the grid solved (or partially solved if the problem is not solved)
"""
function heuristicSolve(t::Array{Int,2})

    n = size(t, 1)
    tCopy = copy(t)

    # True if the grid has completely been filled
    gridFilled = false

    # True if the grid may still have a solution
    gridStillFeasible = true

    # While the grid is not filled and it may still be solvable
    while !gridFilled && gridStillFeasible

        # Coordinates of the most constrained cell
        mcCell = [-1 -1]

        # Values which can be assigned to the most constrained cell
        values = nothing
        
        # Randomly select a cell and a value
        l = ceil.(Int, n * rand())
        c = ceil.(Int, n * rand())
        id = 1

        # For each cell of the grid, while a cell with 0 values has not been found
        while id <= n*n && (values == nothing || size(values, 1)  != 0)

            # If the cell does not have a value
            if tCopy[l, c] == 0

                # Get the values which can be assigned to the cell
                cValues = possibleValues(tCopy, l, c)

                # If it is the first cell or if it is the most constrained cell currently found
                if values == nothing || size(cValues, 1) < size(values, 1)
                    values = cValues
                    mcCell = [l c]
                end 
            end
            
            # Go to the next cell                    
            if c < n
                c += 1
            else
                if l < n
                    l += 1
                    c = 1
                else
                    l = 1
                    c = 1
                end
            end

            id += 1
        end

        # If all the cell have a value
        if values == nothing

            gridFilled = true
            gridStillFeasible = true
        else

            # If a cell cannot be assigned any value
            if size(values, 1) == 0
                gridStillFeasible = false

                # Else assign a random value to the most constrained cell 
            else
                
                newValue = ceil.(Int, rand() * size(values, 1))
                    
                gridStillFeasible = false
                id = 1
                while !gridStillFeasible && id <= size(values, 1)

                    tCopy[mcCell[1], mcCell[2]] = values[rem(newValue, size(values, 1)) + 1]
                    
                    if isGridFeasible(tCopy)
                        gridStillFeasible = true
                    else
                        newValue += 1
                    end

                    id += 1
                    
                end

            end 
        end  
    end  

    return gridStillFeasible, tCopy
    
end 

"""
Number of values which could currently be assigned to a cell

Arguments
- t: array of size n*n with values in [0, 2] (0 if the cell is empty)
- l, c: row and column of the cell

Return
- values: array of integers which do not appear 3 times consecutive or more than n/2 times on line l or column c
"""
function possibleValues(t::Array{Int,2}, l::Int64, c::Int64)

    values = Vector{Int64}()

    for v in 1:2
        if isValid(t, l, c, v)
            values = append!(values, v)
        end 
    end 

    return values
    
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
                    isOptimal, x, resolutionTime = cplexSolve(t)
                    
                    # If a solution is found, write it
                    if isOptimal
                        writeSolution(fout, x)
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

"""
Test if the grid is feasible

Arguments
- t: array of size n*n with values in [0, 2] (0 if the cell is empty)
"""
function isGridFeasible(t::Array{Int,2})

    n = size(t, 1)
    isFeasible = true

    l = 1
    c = 1

    # For each cell (l, c) while previous cells can be assigned a value
    while isFeasible && l <= n

        # If a value is not assigned to (l, c)
        if t[l, c] == 0

            # Test all values v until a value which can be assigned to (l, c) is found
            feasibleValueFound = false
            v = 1

            while !feasibleValueFound && v <= 2

                if isValid(t, l, c, v)
                    feasibleValueFound = true
                end
                
                v += 1
                
            end
            
            if !feasibleValueFound
                isFeasible = false
            end 
        end 

        # Go to the next cell
        if c < n
            c += 1
        else
            l += 1
            c = 1
        end
    end

    return isFeasible
end 
