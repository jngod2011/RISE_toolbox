function this=horzcat(varargin)

for ii=1:length(varargin)
    if ~isequal(class(varargin{ii}),'ts')
        error([mfilename,':: input ',int2str(ii),' must be from class ts'])
    end
    if ii==1
        this=varargin{ii};
    else
        if ~isempty(varargin{ii})
            this=this&varargin{ii};
        end
    end
end
end