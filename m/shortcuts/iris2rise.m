function varargout=iris2rise(varargin)
% converts a basic IRIS file into a RISE one
%
% iris2rise(irisFileName)
% iris2rise(irisFileName,riseFileName)
% iris2rise(irisFileName,riseFileName,stderr_name)

[varargout{1:nargout}]=parser.iris2rise(varargin{:});

end