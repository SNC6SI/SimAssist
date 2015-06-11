function actrec = GenericContextAdd(btobj, varargin)
% Batch function for block types that share the following inherent gene:
% - can be used as sink/source block
console = btobj.Console;
actrec = saRecorder;

i_stru = cellfun(@isstruct, varargin);% get option argument
option = varargin{i_stru};
argsin = varargin(~i_stru); % remove from argument cell
i_argnum = find(cellfun(@isnumeric, argsin), 1); % get block number argument
blknum = varargin{i_argnum};
argsin(i_argnum) = [];% remove from argument cell
pvpair = argsin; % the rest are property-value pairs

if isempty(option)
    option = struct;
end
if isempty(blknum)
    blknum=1;
end

if ~isempty(console) && isfield(console.SessionPara, 'ConnectSide')
    cnnt_type = [btobj.ConnectPort & fliplr(console.SessionPara.ConnectSide)];
else
    cnnt_type = btobj.ConnectPort;
end
% do the job
if blknum>1
    actrec + btobj.AddBlockArray(option, blknum, pvpair{:});
else
    % prepare Selection info
    seladd = false;
    if cnnt_type(1) && cnnt_type(2)
        tgtlns = saFindSystem(gcs, 'line');
        tgtipts = saFindSystem(gcs, 'inport_unconnected');
        tgtopts = saFindSystem(gcs, 'outport_unconnected');
        if ~isempty(tgtlns)
            seladd = true;
            for k=1:numel(tgtlns)
                actrec + btobj.InsertBlockToLine(tgtlns(k),pvpair{:});
            end
        end
        if ~isempty(tgtopts)
            seladd = true;
            actrec + btobj.Terminates(tgtopts, option, pvpair{:});
        end
        if ~isempty(tgtipts)
            seladd = true;
            actrec + btobj.Grounds(tgtipts, option, pvpair{:});
        end
    elseif cnnt_type(1)
        tgtobjs_src = saFindSystem(gcs, 'line_sender');
        if ~isempty(tgtobjs_src)
            seladd = true;
            actrec + btobj.Terminates(tgtobjs_src, option, pvpair{:});
        end
    elseif cnnt_type(2)
        tgtobjs_recv = saFindSystem(gcs, 'line_receiver');
        if ~isempty(tgtobjs_recv)
            seladd = true;
            actrec + btobj.Grounds(tgtobjs_recv, option, pvpair{:});
        end
    end
    if ~seladd% if no selection, add single block
        actrec + btobj.AddBlock(option, pvpair{:});
    end
end
end