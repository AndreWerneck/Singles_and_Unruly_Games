# File with graph functions

# Creating position matrix for helping the connexe constraint
    # Example case n = 5: 
    # [1 2 2 2 3
    #  8 0 0 0 4
    #  8 0 0 0 4
    #  8 0 0 0 4
    #  7 6 6 6 5]

function create_position_matrix(n)
    position_matrix = zeros(Int, n, n)

    position_matrix[1, 1] = 1
    position_matrix[1, n] = 3
    position_matrix[n, n] = 5
    position_matrix[n, 1] = 7
    
    for i in 2:n-1
        position_matrix[1, i] = 2
        position_matrix[i, n] = 4
        position_matrix[n, i] = 6
        position_matrix[i, 1] = 8
    end

    return position_matrix
end
    
function converted_to_array(A)
    B = Array{Int64}(undef, size(A))
    for i in axes(A, 1)
        for j in axes(A, 2)
            B[i, j] = value(A[i, j])
        end
    end
    return B
end