function out = modelfunc(  b1,b2,b3,b4,b5,x )

% Sigmoidal fit function, b1 b2 b3 b4 b5 are the parameters to optimize

out = (((b1^2)./(1.+exp(-(b2^2).*(x-b3)))) + (b4^2) ) / ((b1^2)+(b4^2)+(b5^2));

end

