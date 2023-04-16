print("\033c")
using Random

# """
# Generate an n*n grid

# Argument
# - n: size of the grid
# """
# function generateInstance(n::Int64)

#     t = zeros(Int64, n, n) # Initialize matrix with zeros

#     for i in 1:n
#         for j in 1:n
#             if i > 2 && t[i, j] == t[i-2, j]
#                 # If previous two numbers in the same column are identical, generate a different number
#                 t[i, j] = rand(1:n)
#             elseif j > 2 && t[i, j] == t[i, j-2]
#                 # If previous two numbers in the same row are identical, generate a different number
#                 t[i, j] = rand(1:n)
#             else
#                 # Generate a random number between 1 and n
#                 t[i, j] = rand(1:n)
#             end
#         end
#     end

#     if check_grid_valid(t,n)
#         return t
#     end
    
#     generateInstance(n)
# end

# # check if the grid is valid for the game
# # we cant find more than two equal values consecutives eather in a row or in a column
# #matrix must be at least 3x3 
# function check_grid_valid(t::Matrix{Int64},n::Int64)
#     for row in 1:n
#         for col in 1:n
#             if(row+2)<=n
#                 if ((t[row,col]==t[row+1,col]) && (t[row,col]==t[row+2,col]))
#                     return false
#                 end
#             end

#             if(col+2)<=n
#                 if ((t[row,col]==t[row,col+1]) && (t[row,col]==t[row,col+2]))
#                     return false
#                 end
#             end
#         end
#     end
#     return true
# end
     
function checkConnectivity(maskGrid::Array{Int64})
    visitedElements = zeros(Int64, size(maskGrid))

    n = size(maskGrid, 1)

    # Get the first element that is not masked
    firstElement = findfirst(x -> x == 0, maskGrid)

    function recursiveVisiting(maskGrid::Array{Int64, 2}, visited::Array{Int64, 2}, pos::CartesianIndex)
        n = size(maskGrid, 1)
        if !checkbounds(Bool, visited, pos)
            return
        elseif visited[pos] == 1
            return
        elseif maskGrid[pos] == 1
            return
        end

        visited[pos] = 1
        
        for (i,j) in [(1, 0), (-1, 0), (0, 1), (0, -1)]
            newPos = pos + CartesianIndex(i, j)
            recursiveVisiting(maskGrid, visited, newPos)
        end
    end

    recursiveVisiting(maskGrid, visitedElements, firstElement)
    # Return true if all elements are visited or masked
    return all(visitedElements .| maskGrid .== 1)
end

function generateInstance(n::Int64, density::Float64)

    # TODO
    println("In file generation.jl, in method generateInstance(), TODO: generate an instance")
    board = zeros(Int64, n, n)

    function recursiveBoardConstructor(board::Array{Int64, 2}, posi::Int, posj::Int)
        n = size(board,1)
        if posi > n || posj > n
            return true
        end

        unavailable_values = union(Set(board[posi,:]), Set(board[:, posj]))
        available_values = setdiff(1:n, unavailable_values)
        if isempty(available_values)
            return false
        end

        shuffle!(available_values)
        for value in available_values
            board[posi, posj] = value
            if posj == n
                next_posj = 1
                next_posi = posi+1
            else
                next_posj = posj+1
                next_posi = posi
            end
            if recursiveBoardConstructor(board, next_posi, next_posj) == true
                return true
            end
        end
        board[posi, posj] = 0
        return false
    end

    recursiveBoardConstructor(board, 1, 1)

    valuesToMask = Int64(round(n*n*density))
    maskedValues = 0
    maskGrid = zeros(Int64, n, n)

    function recursiveMasking(maskGrid::Array{Int64,2}, masked::Int64, 
                              toMask::Int64, positionsAvailable::Set{Tuple{Int64,Int64}})
        # Check if marked enough elements or if there are any other element that can be marked
        if masked == toMask
            return true
        elseif isempty(positionsAvailable)
            return false
        end

        # Take a random available position
        n = size(maskGrid, 1)
        pos = rand(positionsAvailable)
        
        # Try masking it and then calling recursion if it does not violate connexitivity
        maskGrid[pos...] = 1
        delete!(positionsAvailable, pos)
        if checkConnectivity(maskGrid) == 1
            # Check for values that are in the set, take in count the values in border
            existingValues = intersect(positionsAvailable, [pos .+ (0, 1), pos .+ (0, -1), pos .+ (1, 0), pos .+ (-1, 0)])
            setdiff!(positionsAvailable, existingValues)
            if recursiveMasking(maskGrid, masked+1, toMask, positionsAvailable) == true
                return true
            end
            union!(positionsAvailable, existingValues)
        end
        maskGrid[pos...] = 0
        
        if recursiveMasking(maskGrid, masked, toMask, positionsAvailable) == true
            return true
        end
        push!(positionsAvailable, pos)
        return false
    end

    positionsAvailable = Set(collect(Iterators.product(ntuple(i -> 1:n, 2)...)))

    foundInstance = recursiveMasking(maskGrid, maskedValues, valuesToMask, positionsAvailable)

    if foundInstance == true
        maskedPositions = Set(findall(x -> x == 1, maskGrid))
        for pos in maskedPositions
            valPositions = setdiff(union(collect(Iterators.product(pos[1], 1:n)),
                                         collect(Iterators.product(1:n, pos[2]))), Tuple(pos))
            val = board[rand(valPositions)...]
            board[pos] = val
        end
    end
    
    return foundInstance, board
end

    