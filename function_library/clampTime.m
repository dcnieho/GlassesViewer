function time = clampTime(hm,time)
% clamps to 0 and end, and rounds to nearest (ideal) sample
time = min(max(round(time*hm.UserData.data.eye.fs)/hm.UserData.data.eye.fs,0),hm.UserData.time.endTime);
end