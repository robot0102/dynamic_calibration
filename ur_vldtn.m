% ------------------------------------------------------------------------
% Load validation trajectory
% ------------------------------------------------------------------------
close all;
staticValidation = 0;

if ~staticValidation
    vldtnTrjctry = parseURData('ur-20_01_17-ptp_10_points.csv', 1, 5346);
%     vldtnTrjctry = parseURData('ur-19_12_23_free.csv', 1, 2005);
    vldtnTrjctry = filterData(vldtnTrjctry);
else
    load('vldtnTrjctrySttcs.mat');
    vldtnTrjctry = vldtnTrjctrySttcs;
end

% -----------------------------------------------------------------------
% Predicting torques
% -----------------------------------------------------------------------
%Constracting regressor matrix
tau_msrd = []; 
i_OLS = {}; i_SDP = {};
tau_OLS = {}; tau_SDP = {};
for j = 1:length(idntfcnTrjctry)+1
    i_OLS{j} = [];
    i_SDP{j} = [];
    tau_SDP{j} = [];
    tau_OLS{j} = [];
end

t1 = reshape(pi_full, [11,6]);
pi_full = reshape(t1(1:10,:), [60,1]);
pi_drvs = t1(11,:)';
for i = 1:length(vldtnTrjctry.t)
    qi = vldtnTrjctry.q(i,:)';
    qdi = vldtnTrjctry.qd_fltrd(i,:)';
    q2di = vldtnTrjctry.q2d_est(i,:)';
    Yi = regressorWithMotorDynamics(qi, qdi, q2di);
    
    Ybi = Yi*baseQR.permutationMatrix(:,1:baseQR.numberOfBaseParameters);
    Yfrctni = frictionRegressor(qdi);
    
    tau1 = M_mtrx_fcn(qi, pi_full)*q2di + C_mtrx_fcn(qi, qdi, pi_full)*qdi + G_vctr_fcn(qi, pi_full)
    tau2 = Ybi*pib_SDP(:,1)
    
    tau_msrd = horzcat(tau_msrd, diag(drvGains)*vldtnTrjctry.i(i,:)');
    
    for j = 1:length(idntfcnTrjctry)
        i_OLS{j} = horzcat(i_OLS{j}, diag(drvGains)\([Ybi Yfrctni]*[pib_OLS(:,j); pifrctn_OLS(:,j)]));
        i_SDP{j} = horzcat(i_SDP{j}, diag(drvGains)\([Ybi Yfrctni]*[pib_SDP(:,j); pifrctn_SDP(:,j)]));
        tau_SDP{j} = horzcat(tau_SDP{j}, [Ybi Yfrctni]*[pib_SDP(:,j); pifrctn_SDP(:,j)]);
        tau_OLS{j} = horzcat(tau_OLS{j}, [Ybi Yfrctni]*[pib_OLS(:,j); pifrctn_OLS(:,j)]);
    end
    i_SDP{j+1} = horzcat(i_SDP{j+1}, diag(drvGains2)\([Ybi Yfrctni]*[pib_SDP(:,j+1); pifrctn_SDP(:,j+1)]));
    
end

%%
clrs = {'r', 'b'};

for i = 1:6
    figure
    hold on
    plot(vldtnTrjctry.t, vldtnTrjctry.i(:,i), 'k-')
    for j = 1:length(idntfcnTrjctry)+1
        plot(vldtnTrjctry.t, i_SDP{j}(i,:), clrs{j}, 'LineWidth',1.5)
    end
    ylabel('\tau, Nm')
    xlabel('t, sec')
    grid on
end







