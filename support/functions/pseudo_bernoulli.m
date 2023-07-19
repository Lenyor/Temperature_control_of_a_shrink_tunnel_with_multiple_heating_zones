function [B] = pseudo_bernoulli(p,size)
    %Bernoulli generator from uniform generator
    
    % Sets seed based on the decimal portion of the current system clock
    B = unifrnd(0,size);
    if B<= p
       B = 1;
    else
       B = 0;
    end
end

