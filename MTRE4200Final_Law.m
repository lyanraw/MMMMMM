classdef MTRE4200Final_Law < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        UIDHTable                 matlab.ui.control.Table
        AddRowButton              matlab.ui.control.Button
        UpdateButton              matlab.ui.control.Button
        DeleteRowButton           matlab.ui.control.Button
        TabGroup                  matlab.ui.container.TabGroup
        FrameParamatersTab        matlab.ui.container.Tab
        xMinEditFieldLabel        matlab.ui.control.Label
        xMinEditField             matlab.ui.control.NumericEditField
        xMaxEditFieldLabel        matlab.ui.control.Label
        xMaxEditField             matlab.ui.control.NumericEditField
        yMinEditFieldLabel        matlab.ui.control.Label
        yMinEditField             matlab.ui.control.NumericEditField
        yMaxEditFieldLabel        matlab.ui.control.Label
        yMaxEditField             matlab.ui.control.NumericEditField
        zMinEditFieldLabel        matlab.ui.control.Label
        zMinEditField             matlab.ui.control.NumericEditField
        zMaxEditFieldLabel        matlab.ui.control.Label
        zMaxEditField             matlab.ui.control.NumericEditField
        axislengthEditFieldLabel  matlab.ui.control.Label
        axislengthEditField       matlab.ui.control.NumericEditField
        TextArea                  matlab.ui.control.TextArea
    end



    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            clear
        end

        % Button pushed function: AddRowButton
        function AddRowButtonPushed(app, event)
        %Allows user to add Rows to table
        DH=app.UIDHTable.get('data');            
        DH=[DH;{'Revolute' 'Radian' 'Theta' 'd' '"r"or"a"' 'Alpha' 'q Value'}];
        
        app.UIDHTable.set('ColumnFormat',({{'Prismatic' 'Revolute'} {'Radian' 'Degree'} 'char' 'char' 'char' 'char' 'char'}),...
                'ColumnEditable', true,...
                'Data', DH);
        assignin('base','DH',DH)
        end

        % Button pushed function: UpdateButton
        function UpdateButtonPushed(app, event)
            DH=app.UIDHTable.get('data');
            syms q [1,4];
            % theta d  r alpha
            Aj_r(q1,q2,q3,q4)=trotz(q1)*transl([0;0;q2])*transl([q3;0;0])*trotx(q4);
            Aj_d(q1,q2,q3,q4)=[ cosd(q1),   -sind(q1)*cosd(q4), sind(q1)*sind(q4),  q3*cosd(q1);
                sind(q1),   cosd(q1)*cosd(q4),  -cosd(q1)*sind(q4), q3*sind(q1);
                0,          sind(q4),           cosd(q4),           q2;
                0,          0,                  0,                  1           ];
            [DHrow,DHcol]=size(DH);
            syms q [1,DHrow];
            qValue=zeros(1,DHrow);
            for m=1:DHrow
                qValue(1,m)=double(str2sym(DH{m,7}));%This helps for next loop
            end
            
            %%
            %Finds H using DH
            %and all other Homogeneous functions
            for m=1:DHrow+1%col
                n=m;
                
                while n>=1
                    if m==n
                        H{m,n}=Aj_r(0,0,0,0);
                        SolvedH{m,n}=double(subs(H{m,n},q,qValue));
                    elseif (m-n==1)
                        DHtheta=str2sym(DH{m-1,3});
                        DHd=str2sym(DH{m-1,4});
                        DHa=str2sym(DH{m-1,5});
                        DHalpha=str2sym(DH{m-1,6});
                        if DH{m-1,2}=="Radian" %Radian
                            H{m,n}=Aj_r(DHtheta,DHd,DHa,DHalpha);
                            SolvedH{m,n}=double(subs(H{m,n},q,qValue));
                        elseif DH{m-1,2}=="Degree" %Degree
                            H{m,n}=Aj_d(DHtheta,DHd,DHa,DHalpha);
                            SolvedH{m,n}=double(subs(H{m,n},q,qValue));
                        end
                    else
                        H{m,n}=H{m-1,n}*H{m,m-1};
                        SolvedH{m,n}=double(subs(H{m,n},q,qValue));
                    end
                    n=n-1;
                end
            end            
            %%
            % parameters for axis
            framePlotLims=[ app.xMinEditField.Value app.xMaxEditField.Value...
                            app.yMinEditField.Value app.yMaxEditField.Value...
                            app.zMinEditField.Value app.zMaxEditField.Value];
            axisLength=app.axislengthEditField.Value;
            %Makes frame plot
            for m=1:DHrow+1
                if m==DHrow+1
                    trplot(SolvedH{m,1},'rgb','frame',num2str(m-1),'axis',framePlotLims,'length',axisLength)
                    hold off
                else
                    trplot(SolvedH{m,1},'rgb','frame',num2str(m-1),'axis',framePlotLims,'length',axisLength)
                    hold on
                end
            end
            %%
            %Makes Jacobean
            SolvedJ=zeros(6,DHrow);
            for m=2:DHrow+1
                if DH{m-1,1}=="Revolute" %Is Rotational
                    SolvedMax=SolvedH{DHrow+1,1}(1:3,4);
                    SolvedCurr=SolvedH{m-1,1}(1:3,4);
                    SolvedDiff=SolvedMax-SolvedCurr;
                    SolvedR=SolvedH{m-1,1}(1:3,3);
                    SolvedC=cross(SolvedR,SolvedDiff);
                    SolvedJ(:,m-1)=[SolvedC;SolvedH{m-1,1}(1:3,3)];
                    dMax=H{DHrow+1,1}(1:3,4);
                    dCurr=H{m-1,1}(1:3,4);
                    dDiff=dMax-dCurr;
                    R=H{m-1,1}(1:3,3);
                    c=cross(R,dDiff);
                    J{m-1}=[c(1,1);c(2,1);c(3,1);H{m-1,1}(1,3);H{m-1,1}(2,3);H{m-1,1}(3,3)];
                elseif DH{m-1,1}=="Prismatic"%is Prismatic
                    J{m-1}={H{m-1,1}(1,3);H{m-1,1}(2,3);H{m-1,1}(3,3);0;0;0};
                    SolvedJ(:,m-1)=[SolvedH{m-1,1}(1:3,3);0;0;0];
                end
            end
            assignin('base','DH',DH)
            assignin('base', 'H',H )
            assignin('base', 'J',J )
            assignin('base','SolvedH',SolvedH)
            assignin('base','SolvedJ',SolvedJ)
            
        end

        % Button pushed function: DeleteRowButton
        function DeleteRowButtonPushed(app, event)
        %Allows user to delete Rows to table 
            DH=app.UIDHTable.get('data');
            [DHrow,DHcol]=size(DH);
            DHrow=DHrow-1;
            data=DH(1:DHrow,:);
            app.UIDHTable.set('Data',data)
            
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1097 417];
            app.UIFigure.Name = 'UI Figure';

            % Create UIDHTable
            app.UIDHTable = uitable(app.UIFigure);
            app.UIDHTable.ColumnName = {'Joint Type'; 'Angle Type'; 'Theta'; 'd'; '''a'' or ''r'''; 'Alpha'; 'q'};
            app.UIDHTable.RowName = {'1'; '2'; '3'; '4'; '5'; '6'; '7'; '8'; '9'};
            app.UIDHTable.ColumnEditable = true;
            app.UIDHTable.Position = [1 233 696 185];

            % Create AddRowButton
            app.AddRowButton = uibutton(app.UIFigure, 'push');
            app.AddRowButton.ButtonPushedFcn = createCallbackFcn(app, @AddRowButtonPushed, true);
            app.AddRowButton.Position = [712 325 100 22];
            app.AddRowButton.Text = 'Add Row';

            % Create UpdateButton
            app.UpdateButton = uibutton(app.UIFigure, 'push');
            app.UpdateButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateButtonPushed, true);
            app.UpdateButton.Position = [712 280 100 22];
            app.UpdateButton.Text = 'Update';

            % Create DeleteRowButton
            app.DeleteRowButton = uibutton(app.UIFigure, 'push');
            app.DeleteRowButton.ButtonPushedFcn = createCallbackFcn(app, @DeleteRowButtonPushed, true);
            app.DeleteRowButton.Position = [713 364 99 23];
            app.DeleteRowButton.Text = 'Delete Row';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [2 1 695 218];

            % Create FrameParamatersTab
            app.FrameParamatersTab = uitab(app.TabGroup);
            app.FrameParamatersTab.Title = 'Frame Paramaters';

            % Create xMinEditFieldLabel
            app.xMinEditFieldLabel = uilabel(app.FrameParamatersTab);
            app.xMinEditFieldLabel.HorizontalAlignment = 'right';
            app.xMinEditFieldLabel.Position = [28 145 31 22];
            app.xMinEditFieldLabel.Text = 'xMin';

            % Create xMinEditField
            app.xMinEditField = uieditfield(app.FrameParamatersTab, 'numeric');
            app.xMinEditField.Position = [74 145 26 22];
            app.xMinEditField.Value = -5;

            % Create xMaxEditFieldLabel
            app.xMaxEditFieldLabel = uilabel(app.FrameParamatersTab);
            app.xMaxEditFieldLabel.HorizontalAlignment = 'right';
            app.xMaxEditFieldLabel.Position = [110 145 34 22];
            app.xMaxEditFieldLabel.Text = 'xMax';

            % Create xMaxEditField
            app.xMaxEditField = uieditfield(app.FrameParamatersTab, 'numeric');
            app.xMaxEditField.Position = [159 145 26 22];
            app.xMaxEditField.Value = 5;

            % Create yMinEditFieldLabel
            app.yMinEditFieldLabel = uilabel(app.FrameParamatersTab);
            app.yMinEditFieldLabel.HorizontalAlignment = 'right';
            app.yMinEditFieldLabel.Position = [29 93 31 22];
            app.yMinEditFieldLabel.Text = 'yMin';

            % Create yMinEditField
            app.yMinEditField = uieditfield(app.FrameParamatersTab, 'numeric');
            app.yMinEditField.Position = [75 93 26 22];
            app.yMinEditField.Value = -5;

            % Create yMaxEditFieldLabel
            app.yMaxEditFieldLabel = uilabel(app.FrameParamatersTab);
            app.yMaxEditFieldLabel.HorizontalAlignment = 'right';
            app.yMaxEditFieldLabel.Position = [111 93 34 22];
            app.yMaxEditFieldLabel.Text = 'yMax';

            % Create yMaxEditField
            app.yMaxEditField = uieditfield(app.FrameParamatersTab, 'numeric');
            app.yMaxEditField.Position = [160 93 26 22];
            app.yMaxEditField.Value = 5;

            % Create zMinEditFieldLabel
            app.zMinEditFieldLabel = uilabel(app.FrameParamatersTab);
            app.zMinEditFieldLabel.HorizontalAlignment = 'right';
            app.zMinEditFieldLabel.Position = [28 41 31 22];
            app.zMinEditFieldLabel.Text = 'zMin';

            % Create zMinEditField
            app.zMinEditField = uieditfield(app.FrameParamatersTab, 'numeric');
            app.zMinEditField.Position = [74 41 26 22];
            app.zMinEditField.Value = -5;

            % Create zMaxEditFieldLabel
            app.zMaxEditFieldLabel = uilabel(app.FrameParamatersTab);
            app.zMaxEditFieldLabel.HorizontalAlignment = 'right';
            app.zMaxEditFieldLabel.Position = [110 41 34 22];
            app.zMaxEditFieldLabel.Text = 'zMax';

            % Create zMaxEditField
            app.zMaxEditField = uieditfield(app.FrameParamatersTab, 'numeric');
            app.zMaxEditField.Position = [159 41 26 22];
            app.zMaxEditField.Value = 5;

            % Create axislengthEditFieldLabel
            app.axislengthEditFieldLabel = uilabel(app.FrameParamatersTab);
            app.axislengthEditFieldLabel.HorizontalAlignment = 'right';
            app.axislengthEditFieldLabel.Position = [211 145 63 22];
            app.axislengthEditFieldLabel.Text = 'axis length';

            % Create axislengthEditField
            app.axislengthEditField = uieditfield(app.FrameParamatersTab, 'numeric');
            app.axislengthEditField.Position = [289 145 100 22];
            app.axislengthEditField.Value = 1;

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.Position = [712 2 386 235];
            app.TextArea.Value = {'DH Parameters.'; 'MUST HAVE FOR FRAMES'; '1.	The xn axis, intersect the zn-1 axis.'; '2.	The xn axis, perpendicular to the zn-1 axis.'; ''; ''; '(ÿ),   rotation of frame n-1 about axis zn-1 to get xn-1 to match xn '; '(ÿ),    rotation of frame n-1 around axis xn to get zn-1 to match zn'; 'ÿaÿ,     displacement between frames, measured only in xn direction.'; 'ÿdÿ,     displacement between frames, measured only in zn-1 direction'; ''; 'For Joint Variable write as q, instead of t1 or d2 and so on'; ''; 'Returns H, Solved H for given qValues'; 'As well as J,and Solved J. Also creates figure of frames'};

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MTRE4200Final_Law

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end