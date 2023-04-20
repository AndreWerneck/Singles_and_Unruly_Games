print("\033c")
using Random

"""
Generate an n*n grid

Argument
- n: size of the grid
"""
function generateInstance(n::Int64)

    t = zeros(Int64, n, n) # Initialize matrix with zeros

    for i in 1:n
        for j in 1:n
            if i > 2 && t[i, j] == t[i-2, j]
                # If previous two numbers in the same column are identical, generate a different number
                t[i, j] = rand(1:n)
            elseif j > 2 && t[i, j] == t[i, j-2]
                # If previous two numbers in the same row are identical, generate a different number
                t[i, j] = rand(1:n)
            else
                # Generate a random number between 1 and n
                t[i, j] = rand(1:n)
            end
        end
    end

    if check_grid_valid(t,n)
        return t
    end
    
    generateInstance(n)
end

# check if the grid is valid for the game
# we cant find more than two equal values consecutives eather in a row or in a column
#matrix must be at least 3x3 
function check_grid_valid(t::Matrix{Int64},n::Int64)
    for row in 1:n
        for col in 1:n
            if(row+2)<=n
                if ((t[row,col]==t[row+1,col]) && (t[row,col]==t[row+2,col]))
                    return false
                end
            end

            if(col+2)<=n
                if ((t[row,col]==t[row,col+1]) && (t[row,col]==t[row,col+2]))
                    return false
                end
            end
        end
    end
    return true
end
            

    