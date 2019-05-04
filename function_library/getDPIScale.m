function scale = getDPIScale()
jScreen = java.awt.Toolkit.getDefaultToolkit.getScreenSize; % real pixels
mScreen = get(0,'ScreenSize');                              % DPI-scaled pixels
scale = [jScreen.width jScreen.height]./mScreen(3:4);
assert(isequal(scale(1),scale(2)),'Restart matlab while the screen you want to run this GUI on is already attached (problem figuring out display scaling)')
scale = scale(1);