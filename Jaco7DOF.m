%%
deg = pi/180;
%robot dim in (cm)
D1=27.55;
D2=20.5;
D3=20.5;
D4=20.73;
D5=10.38;
D6=10.38;
D7=16.00;
e2=00.98;
%%
%Creates Robot
L(1) = Revolute('d',D1,      'a', 0, 'alpha',-pi/2,'flip','offset',-pi);
L(2) = Revolute('d',0,      'a', 0, 'alpha',pi/2);
L(3) = Revolute('d',-D2-D3, 'a', 0, 'alpha',pi/2);
L(4) = Revolute('d',-e2,    'a', 0, 'alpha',pi/2);
L(5) = Revolute('d',-D4-D5, 'a', 0, 'alpha',pi/2);
L(6) = Revolute('d',0,      'a', 0, 'alpha',pi/2);
L(7) = Revolute('d',-D6-D7, 'a', 0, 'alpha', pi,'offset',-pi/2);
jaco7DOF = SerialLink(L, 'name', 'Jaco 7 DOF');
%%
%create positions and runs through postions
q=[ 0       0       0       0       0       0       0;
    180     180     180     180     180     180     180;
    0       100     280     65      10      210     210;
    273     183     390     49      258     288     288;
    323     210     166     88      190     233     233;
    283     163     0       44      265     258     258];



k=1;
newpostion=q(k,:);  
jaco7DOF.plot(newpostion)
while k~=7   
    disredpostion=q(k,:);
    for i=1:7
            while newpostion(i)~=q(k,i)
                
                postion1=abs((newpostion(i)-1)-(disredpostion(i)));
                postion2=abs((newpostion(i)+1)-(disredpostion(i)));
                postion11=abs((newpostion(i)-10)-(disredpostion(i)));
                postion22=abs((newpostion(i)+10)-(disredpostion(i)));
                if postion1<postion2&&postion1<postion11&&postion1<postion22
                    newpostion(i)=newpostion(i)-1;
                elseif postion2<postion1&&postion2<postion11&&postion2<postion22
                    newpostion(i)=newpostion(i)+1;
                elseif postion11<postion1&&postion11<postion2&&postion11<postion22
                    newpostion(i)=newpostion(i)-10;
                elseif postion22<postion1&&postion22<postion2&&postion22<postion11
                    newpostion(i)=newpostion(i)+10;
                end
                jaco7DOF.plot(newpostion*deg) 
            end
    end
    trans=jaco7DOF.fkine(newpostion*deg);
    disp(['postion' num2str(k-1) ': x=' num2str(trans.t(1)) ' y=' num2str(trans.t(2)) ' z=' num2str(trans.t(3))]);
    k=input('Menu \n _______________ \n 1: Home Position \n 2: Position 1 \n 3: Position 2 \n 4: Position 3 \n 5: Position 4 \n 6: Position 5 \n 7: Exit  \n Enter desired selection: ');
end

