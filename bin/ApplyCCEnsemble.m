function [ xyz ] = ApplyCCEnsemble( rgb, ccm )
%% APPLYCCENSEMBLE Apply the method of ensemble colour correction

if size(rgb, 2) > 3
    % This branch is used by GenCCEnsemble
    ensembleXyz = rgb;
else 
    % This branch is used during normal operation
    HomoXyz = ApplyCCLinear(rgb, ccm.ccmHomo);
    LinearXyz = ApplyCCLinear(rgb, ccm.ccmLinear);
    RPXyz = ApplyCCRootPolynomial(rgb, ccm.ccmRP);
    
    ensembleXyz = [HomoXyz, LinearXyz, RPXyz];
end

xyz = ensembleXyz * ccm.ensemble;

end

