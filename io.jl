"""
Read a grid from an input file

- Argument:
inputFile: path of the input file

- Example of input file for a 5x5 grid

3,2,4,3,4
3,1,3,4,5
4,4,1,1,3
1,4,3,5,5
4,3,1,1,4

- Prerequisites
Let n be the grid size.
Each line of the input file must contain n values separated by commas.
A value can be just an integer
"""
function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)
    
    n = length(split(data[1], ","))
    t = Matrix{Int64}(undef, n, n)

    lineNb = 1

    # For each line of the input file
    for line in data

        lineSplit = split(line, ",")

        if size(lineSplit, 1) == n
            for colNb in 1:n
            
                t[lineNb, colNb] = parse(Int64, lineSplit[colNb])           
                
            end
        end 
        
        lineNb += 1
    end

    return t

end

"""
Display a grid represented by a 2-dimensional array

Argument:
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
"""
function displayGrid(t::Matrix{Int64})

    dim = size(t,1)

    # Display the upper border of the grid
    println(" ", "---"^(dim))

    for i in 1:dim
        print("|")
        for j in 1:dim

            print(" $(t[i,j]) ")

        end
        print("|")
        print("\n")
    end

    # Display the lower border of the grid
    println(" ", "---"^(dim))

end

function displaySolution(t::Array{Int64,2},y::Array{Int64,2})

    dim = size(t,1)

    # Display the upper border of the grid
    println(" ", "---"^(dim))

    for i in 1:dim
        print("|")
        for j in 1:dim

            if y[i,j] == 1
                print(" \u25A0 ")
            else 
                print(" $(t[i,j]) ")
            end

        end
        print("|")
        print("\n")
    end

    # Display the lower border of the grid
    println(" ", "---"^(dim))

end

