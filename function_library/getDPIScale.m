function scale = getDPIScale()
jScreen = java.awt.Toolkit.getDefaultToolkit.getScreenSize; % real pixels
mScreen = get(0,'ScreenSize');                              % DPI-scaled pixels
scale = [jScreen.width jScreen.height]./mScreen(3:4);
assert(abs(diff(scale)) < 1e4*eps(min(scale)),'Restart matlab while the screen you want to run this GUI on is already attached (problem figuring out display scaling)')
scale = mean(scale);
