function picoscope4000a_disconnect(pscope)
    try

        % [infoStatus, unitInfo] = invoke(pscope, 'getUnitInfo');
        % disp('Closing picoscope below');
        % disp(infoStatus);
        % disp(unitInfo);
        disconnect(pscope);
        delete(pscope);
    catch ME

        disp('Error closing picoscope');
        disp(ME.message);                   % display error message
        disp(ME.stack(1));              %    display stack
    end
end

% clear all; close all; clc;% clear everything