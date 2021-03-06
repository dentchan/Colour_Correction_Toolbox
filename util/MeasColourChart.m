function [ varargout ] = MeasColourChart( ncols, nrows, filename, ...
    varargin)
%% MEASCOLOURCHART Measure the reflectance spectrum of a colour chart
%
%   [ radiance ] = MeasColourChart( ncols, nrows, filename )
%   [ radiance, xyz, reflectance ] = MeasColourChart( ncols, nrows, ...
%       'name1', value1, ... 'nameN', valueN)
%
%   Example: 
%   [radiance, xyz, reflectance] = MeasColourChart(14, 10, 'xrite.mat', ...
%       'CMF', cmf_xyz, 'CMFwl', cmf_wl, 'illum', illum_avg);
%
%   Mandatory parameters :
%       ncols : The number of columns in this colour checker
%       nrows : The number of rows in this colour checker
%       filename : Where to store the spectrum scan.
%
%   Optional name-value pair parameters :
%       MeterType : The meter type for the MeasSpd function
%       MeasParam : The measurement parameter for the MeasSpd, which
%           defaults to [380 5 81].
%       CMF : The colour matching functions
%       CMFwl : The sampling wavelength associated with the colour
%           matching function.
%       wp : The whitepoint of the colour space
%       illum : The spectrum of the illuminant, note that illum has
%               priority over wp. That is if both illum and wp are
%               supplied, wp will be overridden by the whitepoint
%               calculated by illum.
%
%   Outputs :
%       radiance : radiance measured by the spectroradiometer
%       xyz : xyz calculated using the radiance
%       reflectance : the reflectance of the colour checker,
%

%% Parse the input, and sanity check

if ~isnumeric(ncols) || numel(ncols) ~= 1
    error('MeasColourChart:invalid_ncols', 'Invalid input parameter');
end

if ~isnumeric(nrows) || numel(nrows) ~= 1
    error('MeasColourChart:invalid_nrows', 'Invalid input parameter');
end

if ~ischar(filename)
    error('MeasColourChart:invalid_filename', 'Invalid input parameter');
end

p = inputParser;

% addParameter(p,paramName,default,validationFcn)
addParameter(p, 'MeterType', 5, @(x) isnumeric(x) && numel(x) == 1);
addParameter(p, 'MeasParam', [380 5 81], @(x) isnumeric(x) && ...
    numel(x) == 3);
addParameter(p, 'CMF', [], @(x) isnumeric(x) && ismatrix(x));
addParameter(p, 'CMFwl', [], @(x) isnumeric(x) && isvector(x));
addParameter(p, 'illum', [], @(x) isnumeric(x) && isvector(x));
addParameter(p, 'wp', [], @(x) isnumeric(x) && numel(x) == 3);

parse(p, varargin{:});

meter_type = p.Results.MeterType;
meas_param = p.Results.MeasParam;
cmf = p.Results.CMF;
cmf_wl = p.Results.CMFwl;
wp = p.Results.wp;
illum = p.Results.illum;



%% Main section
% radiance is always returned, hence the preallocation
radiance = zeros(ncols * nrows, meas_param(3));

% if both cmf and cmf_wl are supplied, resmaple cmf.
if ~isempty(cmf) && ~isempty(cmf_wl)
    % resample cmf
    meas_wl = meas_param(1):meas_param(2):...
        meas_param(1)+meas_param(2)*(meas_param(3)-1);
    cmf = InterpData(cmf, cmf_wl, meas_wl);
    cmf_wl = meas_wl;

    % If the user supplied illum, then we use it to calculate wp
    if ~isempty(illum)
        wp = illum' * cmf;
        % preallocate reflectance
        reflectance = zeros(ncols * nrows, meas_param(3));
    else
        if nargout > 2
            error('MeasColourChart:too_many_outputs', ...
                ['Impossible to calculate reflectance, CMF, ',...
                'CMFwl, and/or illum had not been supplied.']);
        end
    end

    % cmf, cmf_wl and wp are all supplied.
    if ~isempty(wp)
        % preallocate xyz
        xyz = zeros(ncols * nrows, 3);
        axis equal;
    else
        % It is impossible to calculate all the outputs, without everything
        % supplied
        if nargout > 1
            error('MeasColourChart:too_many_outputs', ...
                ['Impossible to calculate reflectance, CMF, ',...
                'CMFwl, and/or wp had not been supplied.']);
        end
    end
end

k = 1;
for j = 1:nrows
    for i = 1:ncols
        % These will always run, the output from MeasSpd might need
        % transposing.
        while true
            uiwait(msgbox(['We are on row ', num2str(j), ', column ', ...
                num2str(i), ', patch ', num2str(k), ', press ok to ', ...
                'start measurement']));
            this_radiance = MeasSpd([], meter_type)';
            radiance(k, :) = this_radiance;

            if ~isempty(cmf) && ~isempty(cmf_wl) && ~isempty(wp)
                txyz = (this_radiance * cmf);
                xyz(k,:) = txyz;
                trgb = xyz2rgb(txyz, 'WhitePoint', wp);
                trgb(trgb < 0) = 0;
                trgb(trgb > 1) = 1;
                rectangle('Position', [i * 1, -j * 1, 1, 1], ...
                    'FaceColor', trgb);
                if isempty(illum)
                    save(filename, 'radiance', 'xyz', 'meas_wl');
                else
                    reflectance(k, :) = this_radiance./ illum';
                    save(filename, 'radiance', 'xyz', 'reflectance', ...
                        'meas_wl');
                end
            else
                save(filename, 'radiance', 'meas_wl');
            end
            choice = questdlg('Continue to the next patch?', ...
                'Continue?', ...
                'Yes', 'No', 'Yes');
            if strcmp(choice, 'Yes')
                break;
            end
        end
        k = k + 1;
    end
end

%% Write out varargout
varargout{1} = radiance;

if exist('xyz','var')
    varargout{2} = xyz;
end

if exist('reflectance','var')
    varargout{3} = reflectance;
end

end

