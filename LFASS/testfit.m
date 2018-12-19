function response = testfit(X,y,model,beta,varargin)

% This function is the beginning of the function nlinfit. It is a
% bit modified to return true if teh fit converges, and
% false if not. The aim is to make the program fitfolder run even after a
% non-fittable curve (otherwise it will stop once it encounters a non-
% fittable curve).


if nargin < 4
    error(message('stats:nlinfit:TooFewInputs'));
elseif ~isvector(y)
    error(message('stats:nlinfit:NonVectorY'));
end

% Parse input arguments
[errormodel, weights, errorparam, options, iterative, maxweight] = parseInVarargin(varargin(:));

% Check sizes of the model function's outputs while initializing the fitted
% values, residuals, and SSE at the given starting coefficient values.
model = fcnchk(model);
try
    yfit = model(beta,X);
catch ME
    if isa(model, 'inline')
        m = message('stats:nlinfit:ModelInlineError');
        throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
    elseif strcmp('MATLAB:UndefinedFunction', ME.identifier) ...
            && ~isempty(strfind(ME.message, func2str(model)))
        error(message('stats:nlinfit:ModelFunctionNotFound', func2str( model )));
    else
        m = message('stats:nlinfit:ModelFunctionError',func2str(model));
        throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
    end
end
if ~isequal(size(yfit), size(y))
    expSizeStr = sprintf('%-d-by-',size(y));
    actSizeStr = sprintf('%-d-by-',size(yfit));
    error(message('stats:nlinfit:WrongSizeFunOutput',expSizeStr(1:end-4),actSizeStr(1:end-4)));
end

% Check weights
nanweights = checkWeights(weights, yfit, y);

if strcmp(errormodel, 'exponential')
    % Transform model.
    [y, model] = applyLogTransformation(y, model);
    % Transform yfit as well.
    [yfit, ~] = applyLogTransformation(yfit, []);
end

% Find NaNs in either the responses or in the fitted values at the starting
% point.  Since X is allowed to be anything, we can't just check for rows
% with NaNs, so checking yhat is the appropriate thing.  Those positions in
% the fit will be ignored as missing values.  NaNs that show up anywhere
% else during iteration will be treated as bad values.
nans = (isnan(y(:)) | isnan(yfit(:)) | nanweights(:)); % a col vector
r = y(:) - yfit(:);
r(nans) = [];
n = numel(r);
p = numel(beta);
sse = r'*r;
response = 'true';
% After removing NaNs in either the responses or in the fitted values at 
% the starting point, if n = 0 then stop execution.
if ( n == 0 )
    %error(message('stats:nlinfit:NoUsableObservations'));\
    response = 'false';
end



end









%----------------------- Parse input arguments
function [errModel, weights, errModelParameter, options, iterative, maxweight] = parseInVarargin(varargin)
% Parse input arguments

argsToParse = varargin{:};
options = statset('nlinfit');
iterative = false;

% Process PVP - ErrorModel, Weights and ErrorModelParameter inputs should
% be passed in as PV pairs. statset can be passed in either as PV pair or
% directly as a struct.
numargs = numel(argsToParse);
if numargs > 0 && rem(numargs,2)
    % statset supplied directly as a struct.
    if isstruct(argsToParse{1}) || isempty(argsToParse{1})
        options = argsToParse{1};
        argsToParse = argsToParse(2:end);
    end
end
    
% Parse PV pairs
pnames = {'errormodel','weights', 'options', 'errorparameters', 'maxweight'};
defval = {'constant', 1, options, [], realmax};
[errModel, weights, options, errModelParameter, maxweight] = ...
    internal.stats.parseArgs(pnames, defval, argsToParse{:});

% Validate property values
if ~ischar(errModel)
    error(message('stats:nlinfit:InvalidErrorModel'));
end
ok = {'constant', 'proportional', 'exponential', 'combined'};
okv = find(strncmpi(errModel, ok, numel(errModel)));
if numel(okv) ~= 1
    error(message('stats:nlinfit:InvalidErrorModel'));
end
errModel = ok{okv};

if ~isnumeric(weights) && ~isa(weights, 'function_handle')
    error(message('stats:nlinfit:InvalidWeights'));
end

options = statset(statset('nlinfit'),options);

if numel(errModelParameter)>2 || ~isnumeric(errModelParameter)
    error(message('stats:nlinfit:BadErrorParam'))
end
switch errModel
    case 'combined'
        if isempty(errModelParameter)
            errModelParameter = [1 1];
        elseif numel(errModelParameter)~= 2
            % For combined error model, ErrorModelParameter should be a vector [a b]
            error(message('stats:nlinfit:BadCombinedParam', errModel));
        end
    case 'proportional'
        % Only a should be specified.
        if isempty(errModelParameter)
            errModelParameter = 1;
        elseif numel(errModelParameter)~=1
            error(message('stats:nlinfit:BadErrorParam1', errModel))
        end
    case {'constant', 'exponential'}
        % Only b should be specified.
        if isempty(errModelParameter)
            errModelParameter = 1;
        elseif numel(errModelParameter)~=1
            error(message('stats:nlinfit:BadErrorParam1', errModel))
        end
end

if ~isscalar(maxweight) || ~isreal(maxweight) || maxweight<=0
    error(message('stats:nlinfit:InvalidMaxWeight'));
end

% Check for conflicting error model and weights
if ~strcmpi(errModel, 'constant')
    if isa(weights, 'function_handle') || ~isscalar(weights) || weights~=1
        error(message('stats:nlinfit:ErrorModelWeightConflict'));
    end
end

% Robust fitting and weights
if ~isempty(options.RobustWgtFun) && (~strcmpi(errModel, 'constant') || isa(weights, 'function_handle') || ~isscalar(weights) || weights~=1)
    error(message('stats:nlinfit:ErrorModelRobustConflict'));
end

if any(strcmpi(errModel, {'proportional', 'combined'})) || isa(weights, 'function_handle')
    % Iteratively reweighted fitting required for proportional and
    % combined error model and weights that are a function of
    % predicted values
    iterative = true;
end

end % function parseInVarargin

%----------------------- Check weights
function nanweights = checkWeights(weights, yfit, y)
nanweights = zeros(size(y));

if (isnumeric(weights) && (~isscalar(weights) || weights~=1)) || isa(weights, 'function_handle')
    % If weights are set
    
    if isa(weights, 'function_handle')
        % function handle
        try
            wVec = weights(yfit);
        catch ME
            if isa(weights, 'inline')
                m = message('stats:nlinfit:InlineWeightFunctionError');
                throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
            elseif strcmp('MATLAB:UndefinedFunction', ME.identifier) ...
                    && ~isempty(strfind(ME.message, func2str(weights)))
                error(message('stats:nlinfit:WeightFunctionNotFound',func2str(weights)));
            else
                m = message('stats:nlinfit:WeightFunctionError',func2str(weights));
                throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
            end
        end
    else
        wVec = weights; % fixed weights
    end
    
    nanweights = isnan(wVec);
    % w should be real positive vector of the same size as y
    if any(~isreal(wVec)) || any(wVec(~nanweights)<=0) || numel(wVec)~=numel(y) ||~isvector(wVec) || ~isequal(size(wVec), size(y))
        error(message('stats:nlinfit:InvalidWeights'));
    end
    
end

end % function validateWeights

function e = error_ab(ab,y,f)
g = abs(ab(1)) + abs(ab(2))*abs(f);
e = sum(0.5*((y-f)./g).^2 + log(g));
end % function error_ab

function [y, model] = applyLogTransformation(y, model)
% Exponential, y = f*exp(a*e), or log(y) = log(f) + a*e

if ~isempty(y)
    if ~all(y>0)
        error(message('stats:nlinfit:PositiveYRequired'));
    else
        y = log(max(y,realmin));
    end
end

if ~isempty(model)
    % Exponential error model. Linearize the model as
    %   y = f*exp(a*e), or log(y) = log(f) + a*e
    model = @(phi,X) log(max(model(phi,X),realmin));
end

end % function applyModelTransformations


