# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")
using CPLEX
TOL = 0.00001

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64, density::Float64)

   # True if the current grid has no conflicts
    # (i.e., not twice the same value on a line, column or block)
    isGridValid = false

    t = []

    # While a valid grid is not obtained 
    while !isGridValid

        isGridValid = true
        
        # Array that will contain the generated grid
        t = zeros(Int64, n, n)
        i = 1

        # While the grid is valid and the required number of cells is not filled
        while isGridValid && i < (n*n*density)

            # Randomly select a cell and a value
            l = ceil.(Int, n * rand())
            c = ceil.(Int, n * rand())
            v = ceil.(Int, 2 * rand())

            # True if a value has already been assigned to the cell (l, c)
            isCellFree = t[l, c] == 0

            # True if value v can be set in cell (l, c)
            isValueValid = isValid(t, l, c, v)

            # Number of value that we already tried to assign to cell (l, c)
            attemptCount = 0

            # Number of cells considered in the grid
            testedCells = 1

            # While is it not possible to assign the value to the cell
            # (we assign a value if the cell is free and the value is valid)
            # and while all the cells have not been considered
            while !(isCellFree && isValueValid) && testedCells < n*n

                # If the cell has already been assigned a number or if all the values have been tested for this cell
                if !isCellFree || attemptCount == n
                    
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

                    testedCells += 1
                    isCellFree = t[l, c] == 0
                    isValueValid = isValid(t, l, c, v)
                    attemptCount = 0
                    
                    # If the cell has not already been assigned a value and all the value have not all been tested
                else
                    attemptCount += 1
                    v = rem(v, n) + 1
                end 
            end

            if testedCells == n*n
                isGridValid = false
            else 
                t[l, c] = v
            end

            i += 1
        end
    end

    return t

end 

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid

Generates a solved problem using cplex and erases the cases until the desired density is obtained
"""
function generateInstance2(n::Int64, density::Float64)

    # Create the model
    m = JuMP.Model(CPLEX.Optimizer)

    # x[i,j,k] = 1 if cell (i,j) has color k
    @variable(m, x[1:n, 1:n, 1:2], Bin)

    # only one color per position
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i,j,k] for k in 1:2) == 1)

    # each row and column contains the same number of black and white squares.
    @constraint(m, [i in 1:n, k in 1:2], sum(x[i,j,k] for j in 1:n) == n/2)
    @constraint(m, [j in 1:n, k in 1:2], sum(x[i,j,k] for i in 1:n) == n/2)

    # no three consecutive squares, horizontally or vertically, are the same colour
    @constraint(m, [i in 1:n, j in 1:(n-2), k in 1:2], x[i,j,k] + x[i,j+1,k] + x[i,j+2,k] <=2)
    @constraint(m, [i in 1:(n-2), j in 1:n, k in 1:2], x[i,j,k] + x[i+1,j,k] + x[i+2,j,k] <=2)

    @objective(m, Max, 1)

    # Solve the model
    optimize!(m)

    t = Matrix{Int64}(undef, n, n)
    for l in 1:n
        for c in 1:n
            for k in 1:2
                if JuMP.value(x[l, c, k]) > TOL
                    t[l, c] = k
                end
            end
        end 
    end

    i=0
    while i < (n*n*(1-density))
        # Randomly select a cell
        l = ceil.(Int, n * rand())
        c = ceil.(Int, n * rand())
        
        # if (i,j) is not empty yet
        if t[l,c] != 0 
            # erase the color
            t[l,c] = 0 

            i += 1
        end
    end
    
    return t
end 

"""
Test if cell (l, c) can be assigned value v

Arguments
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
- l, c: considered cell
- v: value considered

Return: true if t[l, c] can be set to v; false otherwise
"""
function isValid(t::Array{Int64, 2}, l::Int64, c::Int64, v::Int64)

    n = size(t, 1)
    isValid = true

    # no three consecutive squares vertically with color v
    if l>2
        if t[l-2,c]==v && t[l-1,c]==v
            isValid = false
        end
    end
    if l<n-1
        if t[l+1,c]==v && t[l+2,c]==v
            isValid = false
        end
    end
    if l>1 && l<n
        if t[l-1,c]==v && t[l+1,c]==v
            isValid = false
        end
    end

    # no three consecutive squares horizontally with color v
    if c>2
        if t[l,c-2]==v && t[l,c-1]==v
            isValid = false
        end
    end
    if c<n-1
        if t[l,c+1]==v && t[l,c+2]==v
            isValid = false
        end
    end
    if c>1 && c<n
        if t[l,c-1]==v && t[l,c+1]==v
            isValid = false
        end
    end

    # each column contains n/2 values v
    num_v = 0
    for l2 in 1:n
        if t[l2, c] == v
            num_v += 1
            if num_v >= n/2
                isValid = false
            end
        end
    end 

    # each row contains n/2 value v
    num_v = 0
    for c2 in 1:n
        if t[l, c2] == v
            num_v += 1
            if num_v >= n/2
                isValid = false
            end
        end
    end 
    
    return isValid
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # For each grid size considered
    for size in [8, 10, 14, 16, 18, 20]

        # For each grid density considered
        for density in 0.1:0.2:0.3

            # Generate 10 instances
            for instance in 1:10

                fileName = "../data/instance_t" * string(size) * "_d" * string(density) * "_" * string(instance) * ".txt"

                if !isfile(fileName)
                    println("-- Generating file " * fileName)
                    #saveInstance(generateInstance(size, density), fileName)
                    saveInstance(generateInstance2(size, density), fileName)
                end 
            end
        end
    end

end
