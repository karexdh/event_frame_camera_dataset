function [ev, hdr] = read_evbin(filename, startIdx, count)
%READ_EVBIN  Read *_cd.bin / *_trigger.bin files written by evt3_raw_to_bin.exe (no Metavision SDK needed)
%
%   [ev, hdr] = read_evbin(filename)                   read all records
%   [ev, hdr] = read_evbin(filename, startIdx, count)  read COUNT records starting at record STARTIDX (1-based)
%   hdr       = read_evbin(filename, 1, 0)             header only (ev is empty)
%
%   CD file      : ev.x (uint16), ev.y (uint16), ev.p (uint8, 0=OFF 1=ON), ev.t (int64, us)
%   Trigger file : ev.p (uint8, 0=falling 1=rising), ev.id (uint8, channel), ev.t (int64, us)
%   Absolute sensor timestamp = double(ev.t) + hdr.time_offset_us
%
%   Example:
%     [cd,  h] = read_evbin('recording_cd.bin', 1, 1e6);   % first 1,000,000 CD events
%     [trg, ~] = read_evbin('recording_trigger.bin');
%     rising   = trg.t(trg.p == 1);

    fid = fopen(filename, 'r', 'ieee-le');
    if fid < 0
        error('read_evbin:open', 'Cannot open file: %s', filename);
    end
    closer = onCleanup(@() fclose(fid));

    magic = fread(fid, [1 8], '*char');
    if ~strcmp(magic, 'EVBIN001')
        error('read_evbin:format', '%s is not an EVBIN file', filename);
    end
    hdr.version        = fread(fid, 1, 'uint16=>double');
    hdr.header_size    = fread(fid, 1, 'uint16=>double');
    hdr.record_type    = fread(fid, 1, 'uint16=>double');
    hdr.record_size    = fread(fid, 1, 'uint16=>double');
    hdr.sensor_width   = fread(fid, 1, 'uint16=>double');
    hdr.sensor_height  = fread(fid, 1, 'uint16=>double');
    fread(fid, 1, 'uint32');                                  % reserved0
    hdr.num_records    = fread(fid, 1, 'uint64=>double');
    hdr.time_offset_us = fread(fid, 1, 'int64=>double');

    switch hdr.record_type
        case 1  % CD:      x uint16 | y uint16 | p uint8 | t int64   (13 bytes)
            fields = {'x', 0, 'uint16', 2; 'y', 2, 'uint16', 2; 'p', 4, 'uint8', 1; 't', 5, 'int64', 8};
            hdr.record_name = 'CD';
        case 2  % Trigger: p uint8 | id uint8 | t int64             (10 bytes)
            fields = {'p', 0, 'uint8', 1; 'id', 1, 'uint8', 1; 't', 2, 'int64', 8};
            hdr.record_name = 'EXT_TRIGGER';
        otherwise
            error('read_evbin:format', 'Unsupported record type %d', hdr.record_type);
    end

    if nargin < 2 || isempty(startIdx), startIdx = 1; end
    startIdx = max(1, floor(startIdx));
    available = max(0, hdr.num_records - startIdx + 1);
    if nargin < 3 || isempty(count)
        count = available;
    else
        count = min(floor(count), available);
    end

    if nargout < 2 && nargin == 3 && count == 0
        ev = hdr;   % header-only call
        return;
    end

    % Read the requested records in blocks as raw bytes, then split the columns with typecast
    rs = hdr.record_size;
    for k = 1:size(fields, 1)
        ev.(fields{k, 1}) = zeros(count, 1, fields{k, 3});
    end
    fseek(fid, hdr.header_size + (startIdx - 1) * rs, 'bof');
    BLOCK = 4e6;   % records per block
    done = 0;
    while done < count
        n = min(BLOCK, count - done);
        raw = fread(fid, [rs, n], '*uint8');
        if size(raw, 2) ~= n
            error('read_evbin:eof', 'Unexpected end of file (file truncated?)');
        end
        idx = done + (1:n);
        for k = 1:size(fields, 1)
            off = fields{k, 2};
            sz  = fields{k, 4};
            bytes = raw(off + 1:off + sz, :);
            ev.(fields{k, 1})(idx) = typecast(bytes(:), fields{k, 3});
        end
        done = done + n;
    end
end
