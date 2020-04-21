function trialIdx = findTrials(obj,fields)
%FINDTRIALS Search for trials which used specific parameters
% trialIdx = findTrials(obj,fields)
%
% Find the index of all trials within the object that used certain
% parameter values, defined in 'fields'. This function is used by
% plotTrials and findRespArray.
%
% This function accepts the following inputs:
%
%   fields      - structure with fields that specify the parameters
%                 requested and their value. Any object property can be
%                 searched - numeric or string value. Partial matches of
%                 strings are found - complete string does not have to be
%                 specified. Parameters in 'fields' with the prefix EXCLUDE
%                 (case sensitive) are used to find trials that do not match
%                 the parameter that follows and its parameter value.
%                 See below for example.
%
%
% This function returns the following outputs:
%
%   trialIdx    - [Nx1] array of trial indices which match the parameter
%                 values given in 'fields'
%
%
% Example use:
%               fields.trial_duration = 3;
%               fields.xGain = 2;
%               fields.PatternStr = 'WF'; % Matches pattern names that
%                                         % include 'WF'
%               fields.EXCLUDEyGain = 0;  % Any trials with yGain = 0 will
%                                         % not be returned in output
%
%               trialIdx = findTrials(obj,fields)
%
%               % Looks for trials where obj.trial_duration == 3,
%               obj.xGain == 2, and strcmp(obj.PatternNum == 1)
%
%
% Parameters specified in 'fields' can be parameters which have been assigned
% for each trial individually (one value for each trial) or for the entire
% Slidebook object (one value for the whole tiff file).
%
% If 'fields' argument is entered as [] then all trials are returned.
%
% See also plotTrials, findRespArray, findF0.

if isempty(obj.TrialStartFrame)
    getTrialtimes(obj);
end

if nargin < 2 || isempty(fields)
    fields = struct; % Create an empty structure. All trials will be returned
else
    assert( isstruct(fields) , 'The input to ''fields'' must be a structure.');
end

% Index all trials in object
all_trials = (1:length(obj.TrialStartFrame))';

if ~isempty( fields )
    
    % Remove any fields with empty values (assuming these were meant to be
    % cleared)
    rmfieldsIdx = find(structfun(@isempty, fields));
    fcell = fieldnames(fields);
    fields = rmfield(fields, fcell(rmfieldsIdx));
    fcell = fieldnames(fields);
    
    % Eliminate trials from all_trials  which don't match each specified
    % parameter, one by one:
    for fidx = 1:length(fcell)
        
        % Detect whether parameter is to be excluded, rather than found
        if length(fcell{fidx}) >= 7 && strcmp( 'EXCLUDE' , fcell{fidx}(1:7) )
            EXCLUDE = 1;
            fprop = fcell{fidx}(8:end);
        else
            EXCLUDE = 0;
            fprop = fcell{fidx};
        end
        if ~isempty( obj.( fprop ) )
            switch ischar( fields.( fcell{fidx} ) )
                
                case 0 % Paramter value is a number
                    if length( obj.( fprop ) ) == length( obj.TrialStartFrame )
                        % There's one value of this paramter per trial:
                        if EXCLUDE
                            all_trials = all_trials ( obj.( fprop )(all_trials)  ~= fields.( fcell{fidx} ) );
                        else
                            all_trials = all_trials ( obj.( fprop )(all_trials)  == fields.( fcell{fidx} ) );
                        end
                        
                    elseif length( obj.( fprop ) ) == 1
                        % There's one value of this paramter per tiff:
                        
                        if obj.( fprop ) == fields.( fcell{fidx} )
                            % If it matches the value requested:
                            
                            if EXCLUDE
                                % all trials are rejected:
                                all_trials = [];
                            else
                                % all trials are accepted:
                                all_trials = all_trials;
                            end
                            
                        else % Otherwise, if it does not match:
                            
                            if EXCLUDE
                                % all trials are accepted:
                                all_trials = all_trials;
                            else
                                % all trials are rejected:
                                all_trials = [];
                            end
                        end
                    end
                    
                    
                case 1 % Paramter value is a string, so we must be careful about
                    % checking length, and make comparisons in a different way:
                    
                    if  iscellstr( obj.( fprop ) )   && ...
                            length ( obj.( fprop ) ) == length ( obj.TrialStartFrame )
                        % There's one value of this paramter for each trial:
                        
                        % Check the first index and make sure it's also a string in
                        % the object
                        assert(ischar( obj.( fprop ){1} ), ['''' fprop ''' is not a string in the object. Try replacing with numeric value.'])
                        
                        % Search for string at each trial index:
                        if EXCLUDE
                            all_trials = all_trials ( ~contains( obj.( fprop )(all_trials), fields.( fcell{fidx} ) ) );
                        else
                            all_trials = all_trials ( contains( obj.( fprop )(all_trials), fields.( fcell{fidx} ) ) );
                        end
                        
                    elseif size( obj.( fprop ) , 1 ) == 1
                        % There's one value of this paramter per tiff:
                        
                        % Check it's also a string in the object
                        assert(ischar( obj.( fprop )), ['''' fprop ''' is not a string in the object. Try replacing with numeric value.'])
                        
                        % If it matches the value requested:
                        if strcmpi( obj.( fprop ), fields.( fcell{fidx} ) )
                            
                            if EXCLUDE
                                % all trials are rejected:
                                all_trials = [];
                            else
                                % all trials are accepted:
                                all_trials = all_trials;
                            end
                            
                        else % Otherwise, if it does not match:
                            
                            if EXCLUDE
                                % all trials are accepted:
                                all_trials = all_trials;
                            else
                                % all trials are rejected:
                                all_trials = [];
                            end
                        end
                        
                    else % There's more than one value of this paramter per tiff,
                        % but not 1 per trial. We can search for a match
                        % anyway, but it might be meaningless - all objects
                        % are likely to contain the same set of this property.
                        
                        % Check the first index and make sure it's also a string in
                        % the object
                        assert(ischar( obj.( fprop ){1} ), ['Requested input ''fields.' fprop ''' is not a string in the object. Try replacing with numeric value.'])
                        
                        disp(['''' fprop ''' is not associated with trials.'])
                        
                        if any( contains( obj.( fprop ), fields.( fcell{fidx} ) ) )
                            if EXCLUDE
                                % all trials are rejected:
                                all_trials = [];
                            else
                                % all trials are accepted:
                                all_trials = all_trials;
                            end
                        else
                            if EXCLUDE
                                % all trials are accepted:
                                all_trials = all_trials;
                            else
                                % all trials are rejected:
                                all_trials = [];
                            end
                        end
                    end
            end
        else % Field does not exist in object:
            all_trials = [];
        end
    end
end

trialIdx = all_trials;

if isempty(trialIdx)
    disp(['No trials found with the requested set of parameters (failed to find ' fcell{fidx} ')']);
else
    disp([num2str(length(trialIdx)) ' trials returned.']);
end