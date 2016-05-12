%% TiltRotor Dynamic model
% Author: Claudio Micheli
% Vedi http://ch.mathworks.com/help/symbolic/performing-symbolic-computations.html#brvfwnf
% Stai comunque usando la convenzione 3-2-1 (ZYX) ma matlab
% moltiplica le matrici da sinistra verso destra, quindi devi scriverle in
% senso opposto -> XYZ 
clear all 
close all

%% Rotation matrix
syms phi theta psi real

R_x = [1 0 0 ; 0 cos(phi) sin(phi); 0 -sin(phi) cos(phi)];
R_y = [cos(theta) 0 -sin(theta); 0 1 0 ; sin(theta) 0 cos(theta)];
R_z = [cos(psi) sin(psi) 0 ; -sin(psi) cos(psi) 0 ; 0 0 1];

R_be = R_x*R_y*R_z;         % Rotation matrix from Earth to Body

R_eb = R_be';               % Rotation matrix from Body to Earth

R_BPi = R_z*R_x;            % Rotation matrix from Propeller group to Body
                            % Per i Momenti sembrerebbe giusto R_x*R_z,
                            % mentre per le forze esterne sembra R_z*R_x
                            
                            


%% External forces and torques
n_rotors = 4;
syms Kt Kq  m integer                             % Aerodinamic coefficients
syms omega_1 omega_2 omega_3 omega_4 alpha_1 alpha_2 alpha_3 alpha_4 real         % Angular velocities of the rotors
syms  b integer                                    %length between rotor and COG
g = 9.81;
Fg = m*[ ;0; 0; g];

%Propeller Thrusts 
%Remember -> we are using NED system, thus thrust is NEGATIVE 
T_p1 = [ 0; 0; -Kt*omega_1^2];
T_p2 = [ 0; 0; -Kt*omega_2^2];
T_p3 = [ 0; 0; -Kt*omega_3^2];
T_p4 = [ 0; 0; -Kt*omega_4^2];

%Propeller drag torques
% We consider POSITIVE TORQUES in CW orientation

tau_d1 = [ 0; 0; -Kq*omega_1^2];            % There is '-' sign since the drag torque is CCW
tau_d2 = [ 0; 0; Kq*omega_2^2];
tau_d3 = [ 0; 0; -Kq*omega_3^2];            % There is '-' sign since the drag torque is CCW
tau_d4 = [ 0; 0; Kq*omega_4^2];

for i=1:n_rotors
    disp('Matrice di rotazione Parziale');
    R_BPi
    R_BPi_axis = subs(R_BPi,psi,(i-1)*-pi/2)       % Again, since we're using a CW numeration we must rotate CW, -> -pi/2 despite pi/2
    R_z_axis = subs(R_z,psi,(i-1)*-pi/2);                                    % Rotation matrix  for the Origin of i-th group propeller

    switch i
        case 1
            disp('Matrice di rotazione 1');
           R_BPi_axis = subs(R_BPi_axis,phi,alpha_1)    % Rotation matrix from group propeller Pi to body 
           F_1 = R_BPi_axis*T_p1
           Op1 = R_z_axis * [ b; 0 ; 0];
           M_1 = cross(Op1,F_1) - R_BPi_axis *tau_d1;
        case 2
            disp('Matrice di rotazione 2');
            R_BPi_axis = subs(R_BPi_axis,phi,alpha_2)
           F_2 = R_BPi_axis*T_p2;
           Op2 = R_z_axis * [ b; 0 ; 0];
           M_2 = cross(Op2,F_2) - R_BPi_axis *tau_d2;
            
        case 3
           disp('Matrice di rotazione 3');
           R_BPi_axis = subs(R_BPi_axis,phi,alpha_3)
           F_3 = R_BPi_axis*T_p3
           Op3 = R_z_axis * [ b; 0 ; 0];
           M_3 = cross(Op3,F_3) - R_BPi_axis *tau_d3;
        case 4
           R_BPi_axis = subs(R_BPi_axis,phi,alpha_4);
           F_4 = R_BPi_axis*T_p4;
           Op4 = R_z_axis * [ b; 0 ; 0];
           M_4 = cross(Op4,F_4) - R_BPi_axis *tau_d4;
    end
end

% Overall thrust force generated by the 4 motors (function of the tilting angle) 
    F_ext = (F_1 + F_2 + F_3 + F_4);
    
    F_ext1 = subs(F_ext,alpha_1,0);
    F_ext2 = subs(F_ext1,alpha_2,0);
    F_ext3 = subs(F_ext2,alpha_3,0);
    F_ext_notilt = subs(F_ext3,alpha_4,0)
                                               

% Overall External torques
M_ext = M_1 + M_2 + M_3 + M_4;
M_ext1 = subs(M_ext,alpha_1,0);
M_ext2 = subs(M_ext1,alpha_2,0);
M_ext3 = subs(M_ext2,alpha_3,0);
M_ext_notilt = subs(M_ext3,alpha_4,0)           % Check torques when alpha_i = 0 -> standard quadcopter configuration


%% Equation of motion computation
syms u v w  p q r N E D

%Traslational
V_b = [ u; v; w];
omega_b = [p;q;r];
P_e = [N; E;D];

cross(omega_b,V_b);

% Rotational
syms Ixx Iyy Izz real

In = diag([Ixx Iyy Izz]);
cross(omega_b,(In*omega_b))

% since wd_b =  [M_ext - wb x (In*wb)]* In^-1  -> vedi appunti quaderno

%% Computation of the Mixer Matrix -> Linearization around equilibrium

J_f = jacobian(F_ext,[omega_1,omega_2,omega_3,omega_4,alpha_1,alpha_2,alpha_3,alpha_4]);
J_M =jacobian(M_ext,[omega_1,omega_2,omega_3,omega_4,alpha_1,alpha_2,alpha_3,alpha_4]);

% Full jacobian taking into account linearized F_ext and M_ext
J= [J_f;J_M];
J_prova = J;

% Jacobian has to be evaluated in the equilibrium point, i.e, alpha_i=pi/2,
% omega_i = omega_hover

syms  omega_hover real;

hover_angle = pi/2;
J1 = subs(J,alpha_1,hover_angle);
J2 = subs(J1,alpha_2,hover_angle);
J3 = subs(J2,alpha_3,hover_angle);
J4 = subs(J3,alpha_4,hover_angle);
J5 = subs(J4,omega_1,omega_hover);
J6 = subs(J5,omega_2,omega_hover);
J7 = subs(J6,omega_3,omega_hover);

% The final jacobian evaluated in the equilibrium point is J_evaluated
J_at_hover = subs(J7,omega_4,omega_hover)


% hover_angle = 0 is wrong, this is just a test to verify it
hover_angle = 0;
J1 = subs(J_prova,alpha_1,hover_angle);
J2 = subs(J1,alpha_2,hover_angle);
J3 = subs(J2,alpha_3,hover_angle);
J4 = subs(J3,alpha_4,hover_angle);
J5 = subs(J4,omega_1,omega_hover);
J6 = subs(J5,omega_2,omega_hover);
J7 = subs(J6,omega_3,omega_hover);

J_at_hover_2 = subs(J7,omega_4,omega_hover);


% Inverse at hover
J_at_hover_inv = pinv(J_at_hover)

