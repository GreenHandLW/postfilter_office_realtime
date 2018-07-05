function varargout = DispAngle(varargin)
% DISPANGLE MATLAB code for DispAngle.fig
%      DISPANGLE, by itself, creates a new DISPANGLE or raises the existing
%      singleton*.
%
%      H = DISPANGLE returns the handle to a new DISPANGLE or the handle to
%      the existing singleton*.
%
%      DISPANGLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DISPANGLE.M with the given input arguments.
%
%      DISPANGLE('Property','Value',...) creates a new DISPANGLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DispAngle_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DispAngle_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DispAngle

% Last Modified by GUIDE v2.5 05-Dec-2017 19:23:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DispAngle_OpeningFcn, ...
                   'gui_OutputFcn',  @DispAngle_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before DispAngle is made visible.
function DispAngle_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DispAngle (see VARARGIN)

% Choose default command line output for DispAngle
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using DispAngle.
if strcmp(get(hObject,'Visible'),'off')
    plot(rand(5));
end

global NS;
NS = 1;
global start;
start = 0;
global recObj;
global dir;
dir = 1;
global fs;
buffer_size = 1024;
fs = 8000;
global deviceReader;
deviceReader = audioDeviceReader('NumChannels',8,'SampleRate',fs,'SamplesPerFrame',buffer_size);
devices = getAudioDevices(deviceReader)
SoundCardNum = input('please select XMOS sound card number:');
deviceReader = audioDeviceReader('NumChannels',8,'SampleRate',fs,'SamplesPerFrame',buffer_size,'Device',devices{SoundCardNum});

%devices = getAudioDevices(deviceReader);
setup(deviceReader);
global deviceWriter;
deviceWriter = audioDeviceWriter('SampleRate',fs);
setup(deviceWriter,zeros(buffer_size,1));

% UIWAIT makes DispAngle wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DispAngle_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% axes(handles.axes1);
% cla;

global deviceReader;
global deviceWriter;
global fs;
global NS;

global dir;
global start;

if NS == 0
    set(handles.pushbutton3,'string','NS OFF....');
    set(handles.pushbutton3, 'BackgroundColor',[1 0 0]);
else
    set(handles.pushbutton3,'string','NS ON....');
    set(handles.pushbutton3, 'BackgroundColor',[0 1 0]);
end


if start == 0
    start = 1;
    set(handles.pushbutton1,'string','recording....');
    set(handles.pushbutton1, 'BackgroundColor',[0 1 0]);
else
    start = 0;
    
    set(handles.pushbutton1,'string','stop');
    set(handles.pushbutton1, 'BackgroundColor',[1 0 0]);
end

d = 0.0418;
inc = 16;
chunk_size = 1024;
frameLength = 256;
overlap = frameLength - inc;
     t = 27;
     c = (331.3+0.606*t);
     tao0 = d/c;
     theta0 = 180;
     alpha = cos(theta0/180*pi);
     beta = 1;
     N = frameLength;

last_acquiredAudio = zeros(overlap,8);
last_output = zeros(overlap,1);
% playData = zeros(chunk_size,1);

L = 1;
% w = randn(L,1);
ang = [90;0];
T = load('T0.mat');
T = T.T0;

while start
    
        acquiredAudio = deviceReader();
    x = [last_acquiredAudio(:,[4,1,7]);acquiredAudio(:,[4,1,7])];
%     size(acquiredAudio)
%     y = DMA(x);
%     playData = [last_output;y(1:end-overlap)];
%     deviceWriter(real(playData));

    y = zeros(chunk_size+overlap,1);
    y(1:overlap) = last_output;
    if NS
        y = postprocessing(x,y,fs,ang,T');
    else
        y = x(:,1);
    end
    
    playData = [y(1:end-overlap)];
    deviceWriter(real(playData));
    
    
    last_output = y(end-overlap+1:end);
    last_acquiredAudio = acquiredAudio(end-overlap+1:end,:);
    

    set(handles.text1,'string',beta);
    theta = 0:0.01:pi/4;
    rho = sin(2*theta).*cos(2*theta);
%     polarplot(theta-22.5/180*pi+ang(1)/180*pi,rho)
    polarplot(theta-22.5/180*pi+(dir-1)*60/180*pi,rho)
    drawnow
end



% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'plot(rand(5))', 'plot(sin(1:0.01:25))', 'bar(1:.5:10)', 'plot(membrane)', 'surf(peaks)'});


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton1.
function pushbutton1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)

% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global dir;
if(dir == 6)
    dir = 1;
else
    dir = dir + 1;
end
set(handles.pushbutton2,'string',dir);


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global NS;
if NS == 1
    NS = 0;
    set(handles.pushbutton3,'string','NS OFF....');
    set(handles.pushbutton3, 'BackgroundColor',[1 0 0]);
else
    NS = 1;
        set(handles.pushbutton3,'string','NS ON....');
    set(handles.pushbutton3, 'BackgroundColor',[0 1 0]);
end
